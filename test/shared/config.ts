import { parsePercentage } from "web3-units";

import { Calibration } from "./calibration";

export const DEFAULT_CALIBRATION = new Calibration(10, 1, 1666969423, 1, 10, parsePercentage(1 - 0.0015));
