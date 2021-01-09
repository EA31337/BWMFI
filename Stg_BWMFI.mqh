/**
 * @file
 * Implements BWMFI strategy based on the Market Facilitation Index indicator
 */

// User input params.
INPUT float BWMFI_LotSize = 0;               // Lot size
INPUT int BWMFI_SignalOpenMethod = 0;        // Signal open method
INPUT float BWMFI_SignalOpenLevel = 1.0f;    // Signal open level
INPUT int BWMFI_SignalOpenFilterMethod = 1;  // Signal open filter method
INPUT int BWMFI_SignalOpenBoostMethod = 0;   // Signal open boost method
INPUT int BWMFI_SignalCloseMethod = 0;       // Signal close method
INPUT float BWMFI_SignalCloseLevel = 1.0f;   // Signal close level
INPUT int BWMFI_PriceStopMethod = 0;         // Price stop method
INPUT float BWMFI_PriceStopLevel = 0;        // Price stop level
INPUT int BWMFI_TickFilterMethod = 1;        // Tick filter method
INPUT float BWMFI_MaxSpread = 4.0;           // Max spread to trade (pips)
INPUT int BWMFI_Shift = 0;                   // Shift (relative to the current bar, 0 - default)
INPUT int BWMFI_OrderCloseTime = -20;        // Order close time in mins (>0) or bars (<0)
INPUT string __BWMFI_Indi_BWMFI_Parameters__ =
    "-- BWMFI strategy: BWMFI indicator params --";  // >>> BWMFI strategy: BWMFI indicator <<<
INPUT int BWMFI_Indi_BWMFI_Shift = 0;                // Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_BWMFI_Params_Defaults : BWMFIParams {
  Indi_BWMFI_Params_Defaults() : BWMFIParams(::BWMFI_Indi_BWMFI_Shift) {}
} indi_bwmfi_defaults;

// Defines struct with default user strategy values.
struct Stg_BWMFI_Params_Defaults : StgParams {
  Stg_BWMFI_Params_Defaults()
      : StgParams(::BWMFI_SignalOpenMethod, ::BWMFI_SignalOpenFilterMethod, ::BWMFI_SignalOpenLevel,
                  ::BWMFI_SignalOpenBoostMethod, ::BWMFI_SignalCloseMethod, ::BWMFI_SignalCloseLevel,
                  ::BWMFI_PriceStopMethod, ::BWMFI_PriceStopLevel, ::BWMFI_TickFilterMethod, ::BWMFI_MaxSpread,
                  ::BWMFI_Shift, ::BWMFI_OrderCloseTime) {}
} stg_bwmfi_defaults;

// Struct to define strategy parameters to override.
struct Stg_BWMFI_Params : StgParams {
  StgParams sparams;

  // Struct constructors.
  Stg_BWMFI_Params(StgParams &_sparams) : sparams(stg_bwmfi_defaults) { sparams = _sparams; }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_BWMFI : public Strategy {
 public:
  Stg_BWMFI(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_BWMFI *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    StgParams _stg_params(stg_bwmfi_defaults);
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<StgParams>(_stg_params, _tf, stg_bwmfi_m1, stg_bwmfi_m5, stg_bwmfi_m15, stg_bwmfi_m30, stg_bwmfi_h1,
                               stg_bwmfi_h4, stg_bwmfi_h8);
    }
    // Initialize indicator.
    BWMFIParams _indi_params(_tf);
    _stg_params.SetIndicator(new Indi_BWMFI(_indi_params));
    // Initialize strategy parameters.
    _stg_params.GetLog().SetLevel(_log_level);
    _stg_params.SetMagicNo(_magic_no);
    _stg_params.SetTf(_tf, _Symbol);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_BWMFI(_stg_params, "BWMFI");
    _stg_params.SetStops(_strat, _strat);
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_BWMFI *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    if (_is_valid) {
      // Green bar: MFI value and volume grow synchronously.
      // Brown bar: occurs when the volume and indicator values fall simultaneously.
      // Blue (false) bar: appears during the decrease in trading volume against the backdrop of the rising prices.
      // Pink (squatting) bar: It appears most often at the end of a protracted trend.
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          // Buy: The appearance of three green bars in a row
          // means that the market is overbought or oversold.
          _result &= _indi[CURR][(int)BWMFI_HISTCOLOR] == MFI_HISTCOLOR_GREEN;
          _result &= _indi[PREV][(int)BWMFI_HISTCOLOR] == MFI_HISTCOLOR_GREEN;
          if (_method == 1) _result &= _indi[PPREV][(int)BWMFI_HISTCOLOR] == MFI_HISTCOLOR_GREEN;
          if (_method == 2) _result &= _indi[PPREV][(int)BWMFI_HISTCOLOR] == MFI_HISTCOLOR_SQUAT;
          if (_method == 3) _result &= _indi[PPREV][(int)BWMFI_HISTCOLOR] == MFI_HISTCOLOR_FAKE;
          if (_method == 4) _result &= _indi[PPREV][(int)BWMFI_HISTCOLOR] == MFI_HISTCOLOR_FADE;
          break;
        case ORDER_TYPE_SELL:
          // Sell: The appearance of three green bars in a row
          // means that the market is overbought or oversold.
          _result &= _indi[CURR][(int)BWMFI_HISTCOLOR] == MFI_HISTCOLOR_GREEN;
          _result &= _indi[PREV][(int)BWMFI_HISTCOLOR] == MFI_HISTCOLOR_GREEN;
          if (_method == 1) _result &= _indi[PPREV][(int)BWMFI_HISTCOLOR] == MFI_HISTCOLOR_GREEN;
          if (_method == 2) _result &= _indi[PPREV][(int)BWMFI_HISTCOLOR] == MFI_HISTCOLOR_SQUAT;
          if (_method == 3) _result &= _indi[PPREV][(int)BWMFI_HISTCOLOR] == MFI_HISTCOLOR_FAKE;
          if (_method == 4) _result &= _indi[PPREV][(int)BWMFI_HISTCOLOR] == MFI_HISTCOLOR_FADE;
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price stop value for profit take or stop loss.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Chart *_chart = sparams.GetChart();
    Indicator *_indi = Data();
    double _trail = _level * _chart.GetPipSize();
    int _bar_count = (int)_level * 10;
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _change_pc = Math::ChangeInPct(_indi[1][0], _indi[0][0]);
    double _default_value = _chart.GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _price_offer = _chart.GetOpenOffer(_cmd);
    double _result = _default_value;
    ENUM_APPLIED_PRICE _ap = _direction > 0 ? PRICE_HIGH : PRICE_LOW;
    switch (_method) {
      case 1:
        _result = _indi.GetPrice(
            _ap, _direction > 0 ? _indi.GetHighest<double>(_bar_count) : _indi.GetLowest<double>(_bar_count));
        break;
      case 2:
        _result = Math::ChangeByPct(_price_offer, (float)_change_pc / _level / 100);
        break;
    }
    _result = _result > 0 ? _result + _trail : 0;
    return (float)_result;
  }
};
