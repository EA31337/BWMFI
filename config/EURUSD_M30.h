/**
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_BWMFI_Params_M30 : Indi_BWMFI_Params {
  Indi_BWMFI_Params_M30() : Indi_BWMFI_Params(indi_bwmfi_defaults, PERIOD_M30) {
    shift = 0;
  }
} indi_bwmfi_m30;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_BWMFI_Params_M30 : StgParams {
  // Struct constructor.
  Stg_BWMFI_Params_M30() : StgParams(stg_bwmfi_defaults) {
    lot_size = 0;
    signal_open_method = 0;
    signal_open_filter = 2;
    signal_open_level = 10;
    signal_open_boost = 8;
    signal_close_method = 0;
    signal_close_level = (float)60;
    price_stop_method = 0;
    price_stop_level = 60;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_bwmfi_m30;
