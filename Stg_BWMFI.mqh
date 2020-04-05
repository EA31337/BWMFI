//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/**
 * @file
 * Implements BWMFI strategy based on the Market Facilitation Index indicator
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_BWMFI.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT string __BWMFI_Parameters__ = "-- BWMFI strategy params --";  // >>> BWMFI <<<
INPUT int BWMFI_Shift = 0;                                          // Shift (relative to the current bar, 0 - default)
INPUT int BWMFI_SignalOpenMethod = 0;                               // Signal open method
INPUT double BWMFI_SignalOpenLevel = 0;                             // Signal open level
INPUT int BWMFI_SignalOpenFilterMethod = 0;                         // Signal open filter method
INPUT int BWMFI_SignalOpenBoostMethod = 0;                          // Signal open boost method
INPUT int BWMFI_SignalCloseMethod = 0;                              // Signal close method
INPUT double BWMFI_SignalCloseLevel = 0;                            // Signal close level
INPUT int BWMFI_PriceLimitMethod = 0;                               // Price limit method
INPUT double BWMFI_PriceLimitLevel = 0;                             // Price limit level
INPUT double BWMFI_MaxSpread = 6.0;                                 // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_BWMFI_Params : StgParams {
  int BWMFI_Shift;
  int BWMFI_SignalOpenMethod;
  double BWMFI_SignalOpenLevel;
  int BWMFI_SignalOpenFilterMethod;
  int BWMFI_SignalOpenBoostMethod;
  int BWMFI_SignalCloseMethod;
  double BWMFI_SignalCloseLevel;
  int BWMFI_PriceLimitMethod;
  double BWMFI_PriceLimitLevel;
  double BWMFI_MaxSpread;

  // Constructor: Set default param values.
  Stg_BWMFI_Params()
      : BWMFI_Shift(::BWMFI_Shift),
        BWMFI_SignalOpenMethod(::BWMFI_SignalOpenMethod),
        BWMFI_SignalOpenLevel(::BWMFI_SignalOpenLevel),
        BWMFI_SignalOpenFilterMethod(::BWMFI_SignalOpenFilterMethod),
        BWMFI_SignalOpenBoostMethod(::BWMFI_SignalOpenBoostMethod),
        BWMFI_SignalCloseMethod(::BWMFI_SignalCloseMethod),
        BWMFI_SignalCloseLevel(::BWMFI_SignalCloseLevel),
        BWMFI_PriceLimitMethod(::BWMFI_PriceLimitMethod),
        BWMFI_PriceLimitLevel(::BWMFI_PriceLimitLevel),
        BWMFI_MaxSpread(::BWMFI_MaxSpread) {}
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

class Stg_BWMFI : public Strategy {
 public:
  Stg_BWMFI(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_BWMFI *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Stg_BWMFI_Params _params;
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Stg_BWMFI_Params>(_params, _tf, stg_bwmfi_m1, stg_bwmfi_m5, stg_bwmfi_m15, stg_bwmfi_m30,
                                      stg_bwmfi_h1, stg_bwmfi_h4, stg_bwmfi_h4);
    }
    // Initialize strategy parameters.
    BWMFIParams bwmfi_params(_tf);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_BWMFI(bwmfi_params), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.BWMFI_SignalOpenMethod, _params.BWMFI_SignalOpenLevel,
                       _params.BWMFI_SignalOpenFilterMethod, _params.BWMFI_SignalOpenBoostMethod,
                       _params.BWMFI_SignalCloseMethod, _params.BWMFI_SignalCloseLevel);
    sparams.SetPriceLimits(_params.BWMFI_PriceLimitMethod, _params.BWMFI_PriceLimitLevel);
    sparams.SetMaxSpread(_params.BWMFI_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_BWMFI(sparams, "BWMFI");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, double _level = 0.0) {
    Chart *_chart = Chart();
    Indicator *_indi = Data();
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
   * Check strategy's opening signal additional filter.
   */
  bool SignalOpenFilter(ENUM_ORDER_TYPE _cmd, int _method = 0) {
    bool _result = true;
    if (_method != 0) {
      // if (METHOD(_method, 0)) _result &= Trade().IsTrend(_cmd);
      // if (METHOD(_method, 1)) _result &= Trade().IsPivot(_cmd);
      // if (METHOD(_method, 2)) _result &= Trade().IsPeakHours(_cmd);
      // if (METHOD(_method, 3)) _result &= Trade().IsRoundNumber(_cmd);
      // if (METHOD(_method, 4)) _result &= Trade().IsHedging(_cmd);
      // if (METHOD(_method, 5)) _result &= Trade().IsPeakBar(_cmd);
    }
    return _result;
  }

  /**
   * Gets strategy's lot size boost (when enabled).
   */
  double SignalOpenBoost(ENUM_ORDER_TYPE _cmd, int _method = 0) {
    bool _result = 1.0;
    if (_method != 0) {
      // if (METHOD(_method, 0)) if (Trade().IsTrend(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 1)) if (Trade().IsPivot(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 2)) if (Trade().IsPeakHours(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 3)) if (Trade().IsRoundNumber(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 4)) if (Trade().IsHedging(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 5)) if (Trade().IsPeakBar(_cmd)) _result *= 1.1;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, int _method = 0, double _level = 0.0) {
    return SignalOpen(Order::NegateOrderType(_cmd), _method, _level);
  }

  /**
   * Gets price limit value for profit take or stop loss.
   */
  double PriceLimit(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, double _level = 0.0) {
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    switch (_method) {
      case 0: {
        // @todo
      }
    }
    return _result;
  }
};
