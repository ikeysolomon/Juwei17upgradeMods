// -------------------------------------------------------------------------------------------------
// Pin map for JUWEI17 (ESP32S)
#pragma once

#if defined(ESP32)

#if SERIAL_A_BAUD_DEFAULT != OFF
  #define SERIAL_A              Serial
#endif
#if SERIAL_B_BAUD_DEFAULT != OFF
  #define SERIAL_B              Serial2
  #define SERIAL_B_RX_PIN       16
  #define SERIAL_B_TX_PIN       17
#endif

#if defined(STEP_DIR_TMC_UART_PRESENT) || defined(SERVO_TMC2209_PRESENT)
  #if defined(SERIAL_TMC_HARDWARE_UART)
    #define SERIAL_TMC          Serial1
    #define SERIAL_TMC_BAUD     115200
    #define SERIAL_TMC_RX       23
    #define SERIAL_TMC_TX       5
    #define SERIAL_TMC_ADDRESS_MAP(axis) ((axis == 0) ? 0 : ((axis == 1) ? 1 : 3))
  #endif
#endif

#define AUX2_PIN                4
#define AUX3_PIN                21
#define AUX4_PIN                22
#define AUX7_PIN                39
#define AUX8_PIN                25

#ifndef ONE_WIRE_PIN
  #define ONE_WIRE_PIN          AUX8_PIN
#endif
#define ADDON_GPIO0_PIN         26
#ifndef ADDON_RESET_PIN
  #define ADDON_RESET_PIN       AUX2_PIN
#endif

#ifndef PEC_SENSE_PIN
  #define PEC_SENSE_PIN         36
#endif

#ifndef STATUS_LED_PIN
  #define STATUS_LED_PIN        AUX8_PIN
#endif
#define MOUNT_LED_PIN           STATUS_LED_PIN
#ifndef RETICLE_LED_PIN
  #define RETICLE_LED_PIN       STATUS_LED_PIN
#endif

#ifndef STATUS_BUZZER_PIN
  #define STATUS_BUZZER_PIN     AUX8_PIN
#endif

#ifndef PPS_SENSE_PIN
  #define PPS_SENSE_PIN         AUX7_PIN
#endif

#ifndef LIMIT_SENSE_PIN
  #define LIMIT_SENSE_PIN       AUX7_PIN
#endif

#define SHARED_DIRECTION_PINS
#define SHARED_ENABLE_PIN       12

#define AXIS1_ENABLE_PIN        SHARED
#define AXIS1_M0_PIN            OFF
#define AXIS1_M1_PIN            OFF
#define AXIS1_M2_PIN            OFF
#if AXIS4_POWER_DOWN != ON
  #define AXIS1_M3_PIN          AUX2_PIN
#endif
#define AXIS1_STEP_PIN          18
#define AXIS1_DIR_PIN           0
#ifndef AXIS1_SENSE_HOME_PIN
  #define AXIS1_SENSE_HOME_PIN  AUX3_PIN
#endif

#define AXIS2_ENABLE_PIN        SHARED
#define AXIS2_M0_PIN            OFF
#define AXIS2_M1_PIN            OFF
#define AXIS2_M2_PIN            OFF
#if AXIS4_POWER_DOWN != ON
  #define AXIS2_M3_PIN          AUX2_PIN
#endif
#define AXIS2_STEP_PIN          27
#define AXIS2_DIR_PIN           26
#ifndef AXIS2_SENSE_HOME_PIN
  #define AXIS2_SENSE_HOME_PIN  AUX4_PIN
#endif

#define AXIS3_ENABLE_PIN        OFF
#define AXIS3_M0_PIN            OFF
#define AXIS3_M1_PIN            OFF
#define AXIS3_M2_PIN            OFF
#define AXIS3_M3_PIN            OFF
#define AXIS3_STEP_PIN          2
#define AXIS3_DIR_PIN           15

#if !defined(SERIAL_TMC_HARDWARE_UART) && AXIS4_POWER_DOWN == ON
  #define AXIS4_ENABLE_PIN      AUX2_PIN
#endif
#define AXIS4_M0_PIN            OFF
#define AXIS4_M1_PIN            OFF
#define AXIS4_M2_PIN            OFF
#define AXIS4_M3_PIN            OFF
#define AXIS4_STEP_PIN          19
#define AXIS4_DIR_PIN           15

#define AXIS5_ENABLE_PIN        OFF
#define AXIS5_M0_PIN            OFF
#define AXIS5_M1_PIN            OFF
#define AXIS5_M2_PIN            OFF
#define AXIS5_M3_PIN            OFF
#define AXIS5_STEP_PIN          2
#define AXIS5_DIR_PIN           15

#define ST4_RA_W_PIN            34
#define ST4_DEC_S_PIN           32
#define ST4_DEC_N_PIN           33
#define ST4_RA_E_PIN            35

#else
#error "Wrong processor for this configuration!"
#endif