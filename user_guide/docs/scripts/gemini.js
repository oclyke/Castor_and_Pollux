import { Teeth } from "/winter.js";
import { Uint8Array_to_hex } from "./utils.js";
import GemSettings from "./gem_settings.js";
import GemMonitorUpdate from "./gem_monitor_update.js";
import _struct from "./struct.mjs";

function strip_response(response) {
    return response.data.slice(3, -1);
}

export default class Gemini {
    constructor(midi) {
        this.midi = midi;
    }

    async get_version() {
        /* (command 0x01 - hello) */
        let response = await this.midi.transact(
            new Uint8Array([0xf0, 0x77, 0x01, 0xf7])
        );
        return new TextDecoder("ascii").decode(strip_response(response));
    }

    async get_serial_number() {
        /* (command 0x0f - get serial number) */
        const response = await this.midi.transact(
            new Uint8Array([0xf0, 0x77, 0x0f, 0xf7])
        );
        const decoded = Teeth.decode(strip_response(response));
        return {
            serial: Uint8Array_to_hex(decoded.slice(0, 17)),
            revision: decoded.at(16) ?? 4,
        };
    }

    async load_settings() {
        /* Command 0x18: read settings */
        console.log("Loading settings from device...");

        const timeout = new Promise((_, reject) => {
            setTimeout(() => reject("timeout"), 1000);
        });

        const response = await Promise.race([
            timeout,
            this.midi.transact(new Uint8Array([0xf0, 0x77, 0x18, 0xf7])),
        ]);

        const encoded_data = strip_response(response);
        const decoded_data = Teeth.decode(encoded_data);
        return GemSettings.unpack(decoded_data);
    }

    async save_settings(settings) {
        /* Command 0x19: write settings */
        const settings_data = settings.pack();
        const encoded_data = Teeth.encode(settings_data);
        const midi_message = new Uint8Array(4 + encoded_data.length);
        midi_message.set([0xf0, 0x77, 0x19]);
        midi_message.set(encoded_data, 3);
        midi_message[midi_message.length - 1] = 0xf7;
        await this.midi.transact(midi_message);
    }

    async soft_reset() {
        /* Command 0x11: soft reset */
        await this.midi.transact(new Uint8Array([0xf0, 0x77, 0x11, 0xf7]));
    }

    async enable_monitoring(callback) {
        /* Command 0x10: monitor */
        await this.midi.transact(
            new Uint8Array([0xf0, 0x77, 0x10, 0x01, 0xf7])
        );

        this.midi.input.onmidimessage = function (msg) {
            const encoded_data = strip_response(msg);
            const decoded_data = Teeth.decode(encoded_data);
            const update = GemMonitorUpdate.unpack(decoded_data);
            callback(update);
        };
    }

    async disable_monitoring() {
        /* Command 0x10: monitor */
        await this.midi.transact(
            new Uint8Array([0xf0, 0x77, 0x10, 0x01, 0xf7])
        );
    }

    async write_lut_entry(index, period, castor_value, pollux_value) {
        /* (command 0x0A - write lut entry) */
        const request = pack_and_encode_request(0x0a, ">BIHH", [
            index,
            period,
            castor_value,
            pollux_value,
        ]);
        return await this.midi.transact(new Uint8Array(request));
    }

    async save_lut_table() {
        return await this.midi.transact(
            new Uint8Array([0xf0, 0x77, 0x0b, 0xf7])
        );
    }

    async read_adc(channel) {
        /* (command 0x04 - read ADC) */
        const response = await this.midi.transact(
            new Uint8Array([0xf0, 0x77, 0x04, channel, 0xf7])
        );
        const result_buf = Teeth.decode(strip_response(response));
        const result_view = new DataView(result_buf.buffer, 0);
        return result_view.getUint16(0);
    }

    async read_adc_average(channel, samples) {
        const results = [];
        for (let i = 0; i < samples; i++) {
            results.push(await this.read_adc(channel));
        }
        return (
            results.reduce((x, y) => {
                return x + y;
            }, 0) / results.length
        );
    }

    code_to_volts(rev, code) {
        const resolution = 4096;
        const res_m_1 = resolution - 1;
        let v_min, v_max;

        if (rev < 5) {
            v_min = 0;
            v_max = 6;
        } else {
            v_min = -0.5;
            v_max = 6.1;
        }

        const v_range = Math.abs(v_min) + Math.abs(v_max);

        code = res_m_1 - code;

        return v_min + (v_range - (code / res_m_1) * v_range);
    }

    volts_to_code(rev, volts) {
        const resolution = 4096;
        const res_m_1 = resolution - 1;
        let v_min, v_max;

        if (rev < 5) {
            v_min = 0;
            v_max = 6;
        } else {
            v_min = -0.5;
            v_max = 6.1;
        }

        const v_range = Math.abs(v_min) + Math.abs(v_max);

        let code = ((volts - v_min) / v_range) * res_m_1;
        code = res_m_1 - code;
        return code;
    }
}

function pack_and_encode_request(command, format_str, args) {
    const packed = _struct(format_str).pack(...args);
    return encode_request(command, new Uint8Array(packed));
}

function encode_request(command, data) {
    const encoded_data = Teeth.encode(data);
    const midi_message = new Uint8Array(4 + encoded_data.length);
    midi_message.set([0xf0, 0x77, command]);
    midi_message.set(encoded_data, 3);
    midi_message[midi_message.length - 1] = 0xf7;
    return midi_message;
}
