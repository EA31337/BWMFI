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
INPUT int BWMFI_Active_Tf = 0;  // Activated timeframes (1-255) [M1=1,M5=2,M15=4,M30=8,H1=16,H2=32,H4=64...]
INPUT ENUM_TRAIL_TYPE BWMFI_TrailingStopMethod = 22;   // Trail stop method
INPUT ENUM_TRAIL_TYPE BWMFI_TrailingProfitMethod = 1;  // Trail profit method
INPUT double BWMFI_SignalOpenLevel = 0.00000000;       // Signal open level
INPUT int BWMFI_Shift = 0;                             // Shift (relative to the current bar, 0 - default)
INPUT int BWMFI_SignalBaseMethod = 0;                  // Signal base method (0-
INPUT int BWMFI_SignalOpenMethod1 = 0;                 // Open condition 1 (0-1023)
INPUT int BWMFI_SignalOpenMethod2 = 0;                 // Open condition 2 (0-)
INPUT double BWMFI_SignalCloseLevel = 0.00000000;      // Signal close level
INPUT ENUM_MARKET_EVENT BWMFI_SignalCloseMethod1 = C_BWMFI_BUY_SELL;  // Close condition 1
INPUT ENUM_MARKET_EVENT BWMFI_SignalCloseMethod2 = C_BWMFI_BUY_SELL;  // Close condition 2
INPUT double BWMFI_MaxSpread = 6.0;                                   // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_BWMFI_Params : Stg_Params {
  int BWMFI_Shift;
  ENUM_TRAIL_TYPE BWMFI_TrailingStopMethod;
  ENUM_TRAIL_TYPE BWMFI_TrailingProfitMethod;
  double BWMFI_SignalOpenLevel;
  long BWMFI_SignalBaseMethod;
  long BWMFI_SignalOpenMethod1;
  long BWMFI_SignalOpenMethod2;
  double BWMFI_SignalCloseLevel;
  ENUM_MARKET_EVENT BWMFI_SignalCloseMethod1;
  ENUM_MARKET_EVENT BWMFI_SignalCloseMethod2;
  double BWMFI_MaxSpread;

  // Constructor: Set default param values.
  Stg_BWMFI_Params()
      : BWMFI_Shift(::BWMFI_Shift),
        BWMFI_TrailingStopMethod(::BWMFI_TrailingStopMethod),
        BWMFI_TrailingProfitMethod(::BWMFI_TrailingProfitMethod),
        BWMFI_SignalOpenLevel(::BWMFI_SignalOpenLevel),
        BWMFI_SignalBaseMethod(::BWMFI_SignalBaseMethod),
        BWMFI_SignalOpenMethod1(::BWMFI_SignalOpenMethod1),
        BWMFI_SignalOpenMethod2(::BWMFI_SignalOpenMethod2),
        BWMFI_SignalCloseLevel(::BWMFI_SignalCloseLevel),
        BWMFI_SignalCloseMethod1(::BWMFI_SignalCloseMethod1),
        BWMFI_SignalCloseMethod2(::BWMFI_SignalCloseMethod2),
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
    switch (_tf) {
      case PERIOD_M1: {
        Stg_BWMFI_EURUSD_M1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M5: {
        Stg_BWMFI_EURUSD_M5_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M15: {
        Stg_BWMFI_EURUSD_M15_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M30: {
        Stg_BWMFI_EURUSD_M30_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H1: {
        Stg_BWMFI_EURUSD_H1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H4: {
        Stg_BWMFI_EURUSD_H4_Params _new_params;
        _params = _new_params;
      }
    }
    // Initialize strategy parameters.
    ChartParams cparams(_tf);
    IndicatorParams bwmfi_iparams(10, INDI_BWMFI);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_BWMFI(bwmfi_iparams, cparams), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.BWMFI_SignalBaseMethod, _params.BWMFI_SignalOpenMethod1, _params.BWMFI_SignalOpenMethod2,
                       _params.BWMFI_SignalCloseMethod1, _params.BWMFI_SignalCloseMethod2,
                       _params.BWMFI_SignalOpenLevel, _params.BWMFI_SignalCloseLevel);
    sparams.SetStops(_params.BWMFI_TrailingProfitMethod, _params.BWMFI_TrailingStopMethod);
    sparams.SetMaxSpread(_params.BWMFI_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_BWMFI(sparams, "BWMFI");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    bool _result = false;
    double bwmfi_0 = ((Indi_BWMFI *)this.Data()).GetValue(0);
    double bwmfi_1 = ((Indi_BWMFI *)this.Data()).GetValue(1);
    double bwmfi_2 = ((Indi_BWMFI *)this.Data()).GetValue(2);
    if (_signal_method == EMPTY) _signal_method = GetSignalBaseMethod();
    if (_signal_level == EMPTY) _signal_level = GetSignalOpenLevel();
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        /*
          bool _result = BWMFI_0[LINE_LOWER] != 0.0 || BWMFI_1[LINE_LOWER] != 0.0 || BWMFI_2[LINE_LOWER] != 0.0;
          if (METHOD(_signal_method, 0)) _result &= Open[CURR] > Close[CURR];
        */
        break;
      case ORDER_TYPE_SELL:
        /*
          bool _result = BWMFI_0[LINE_UPPER] != 0.0 || BWMFI_1[LINE_UPPER] != 0.0 || BWMFI_2[LINE_UPPER] != 0.0;
          if (METHOD(_signal_method, 0)) _result &= Open[CURR] < Close[CURR];
        */
        break;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    if (_signal_level == EMPTY) _signal_level = GetSignalCloseLevel();
    return SignalOpen(Order::NegateOrderType(_cmd), _signal_method, _signal_level);
  }
};
