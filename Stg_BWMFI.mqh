/**
 * @file
 * Implements BWMFI strategy based on the Market Facilitation Index indicator
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_BWMFI.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT float BWMFI_LotSize = 0;               // Lot size
INPUT int BWMFI_SignalOpenMethod = 0;        // Signal open method
INPUT float BWMFI_SignalOpenLevel = 0;       // Signal open level
INPUT int BWMFI_SignalOpenFilterMethod = 0;  // Signal open filter method
INPUT int BWMFI_SignalOpenBoostMethod = 0;   // Signal open boost method
INPUT int BWMFI_SignalCloseMethod = 0;       // Signal close method
INPUT float BWMFI_SignalCloseLevel = 0;      // Signal close level
INPUT int BWMFI_PriceLimitMethod = 0;        // Price limit method
INPUT float BWMFI_PriceLimitLevel = 0;       // Price limit level
INPUT int BWMFI_TickFilterMethod = 0;        // Tick filter method
INPUT float BWMFI_MaxSpread = 6.0;           // Max spread to trade (pips)
INPUT int BWMFI_Shift = 0;                   // Shift (relative to the current bar, 0 - default)

// Structs.

// Defines struct with default user strategy values.
struct Stg_BWMFI_Params_Defaults : StgParams {
  Stg_BWMFI_Params_Defaults()
      : StgParams(::BWMFI_SignalOpenMethod, ::BWMFI_SignalOpenFilterMethod, ::BWMFI_SignalOpenLevel,
                  ::BWMFI_SignalOpenBoostMethod, ::BWMFI_SignalCloseMethod, ::BWMFI_SignalCloseLevel,
                  ::BWMFI_PriceLimitMethod, ::BWMFI_PriceLimitLevel, ::BWMFI_TickFilterMethod, ::BWMFI_MaxSpread,
                  ::BWMFI_Shift) {}
} stg_bwmfi_defaults;

// Struct to define strategy parameters to override.
struct Stg_BWMFI_Params : StgParams {
  StgParams sparams;

  // Struct constructors.
  Stg_BWMFI_Params(StgParams &_sparams) : sparams(stg_bwmfi_defaults) { sparams = _sparams; }
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_H8.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

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
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0) {
    Indi_BWMFI *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    double level = _level * Chart().GetPipSize();
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result &= fabs(_indi[CURR].value[BWMFI_BUFFER] - _indi[PREV].value[BWMFI_BUFFER]) > _level;
        if (METHOD(_method, 0)) _result &= _indi[CURR].value[BWMFI_HISTCOLOR] == MFI_HISTCOLOR_GREEN;
        if (METHOD(_method, 1)) _result &= _indi[CURR].value[BWMFI_HISTCOLOR] == MFI_HISTCOLOR_SQUAT;
        if (METHOD(_method, 2)) _result &= _indi[CURR].value[BWMFI_HISTCOLOR] == MFI_HISTCOLOR_FAKE;
        if (METHOD(_method, 3)) _result &= _indi[CURR].value[BWMFI_HISTCOLOR] == MFI_HISTCOLOR_FADE;
        if (METHOD(_method, 4)) _result &= _indi[PREV].value[BWMFI_HISTCOLOR] == MFI_HISTCOLOR_GREEN;
        if (METHOD(_method, 5)) _result &= _indi[PREV].value[BWMFI_HISTCOLOR] == MFI_HISTCOLOR_SQUAT;
        if (METHOD(_method, 6)) _result &= _indi[PREV].value[BWMFI_HISTCOLOR] == MFI_HISTCOLOR_FAKE;
        if (METHOD(_method, 7)) _result &= _indi[PREV].value[BWMFI_HISTCOLOR] == MFI_HISTCOLOR_FADE;
        break;
      case ORDER_TYPE_SELL:
        _result &= fabs(_indi[CURR].value[BWMFI_BUFFER] - _indi[PREV].value[BWMFI_BUFFER]) > _level;
        if (METHOD(_method, 0)) _result &= _indi[CURR].value[BWMFI_HISTCOLOR] == MFI_HISTCOLOR_GREEN;
        if (METHOD(_method, 1)) _result &= _indi[CURR].value[BWMFI_HISTCOLOR] == MFI_HISTCOLOR_SQUAT;
        if (METHOD(_method, 2)) _result &= _indi[CURR].value[BWMFI_HISTCOLOR] == MFI_HISTCOLOR_FAKE;
        if (METHOD(_method, 3)) _result &= _indi[CURR].value[BWMFI_HISTCOLOR] == MFI_HISTCOLOR_FADE;
        if (METHOD(_method, 4)) _result &= _indi[PREV].value[BWMFI_HISTCOLOR] == MFI_HISTCOLOR_GREEN;
        if (METHOD(_method, 5)) _result &= _indi[PREV].value[BWMFI_HISTCOLOR] == MFI_HISTCOLOR_SQUAT;
        if (METHOD(_method, 6)) _result &= _indi[PREV].value[BWMFI_HISTCOLOR] == MFI_HISTCOLOR_FAKE;
        if (METHOD(_method, 7)) _result &= _indi[PREV].value[BWMFI_HISTCOLOR] == MFI_HISTCOLOR_FADE;
        break;
    }
    return _result;
  }

  /**
   * Gets price limit value for profit take or stop loss.
   */
  float PriceLimit(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_BWMFI *_indi = Data();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    switch (_method) {
      case 0: {
        int _bar_count1 = (int)_level * 10;
        _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count1))
                                 : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count1));
        break;
      }
      case 1: {
        int _bar_count2 = (int)_level * 10;
        _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count2))
                                 : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count2));
        break;
      }
    }
    return (float)_result;
  }
};
