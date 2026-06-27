import board
import busio
import adafruit_adxl34x
import neopixel
import time
import math
import supervisor
from adafruit_ble import BLERadio
from adafruit_ble.advertising.standard import ProvideServicesAdvertisement
from adafruit_ble.services.nordic import UARTService

# Simple circular buffer implementation
class CircularBuffer:
    def __init__(self, size):
        self.size = size
        self.buffer = []
        self.index = 0

    def append(self, item):
        if len(self.buffer) < self.size:
            self.buffer.append(item)
        else:
            self.buffer[self.index] = item
            self.index = (self.index + 1) % self.size

    def get_all(self):
        return self.buffer

    def is_full(self):
        return len(self.buffer) == self.size

    def clear(self):
        self.buffer = []
        self.index = 0

# Initialize I2C bus
i2c = board.STEMMA_I2C()

# Initialize ADXL345 accelerometer
accelerometer = adafruit_adxl34x.ADXL345(i2c)

# Initialize the NeoPixel LED on QT Py ESP32
pixel = neopixel.NeoPixel(board.NEOPIXEL, 1, brightness=0.3)

# Initialize BLE
ble = BLERadio()
uart_service = UARTService()
advertisement = ProvideServicesAdvertisement(uart_service)
ble.name = "FallDetector"

# Fall detection parameters
FREEFALL_THRESHOLD = 0.5
IMPACT_THRESHOLD = 2.5
FREEFALL_DURATION = 0
LED_ALERT_DURATION = 5

# SIMPLE instability detection parameters
HISTORY_SIZE = 50  # 0.5 seconds of data at 100Hz

# Key insight: Normal walking is SMOOTH. Shuffling/wobbling is JERKY and IRREGULAR.

# Fall prevention paramaters
SMOOTHNESS_THRESHOLD = 0.25             # How "smooth" the acceleration changes are
IRREGULARITY_THRESHOLD = 0.20           # How inconsistent the movements are
MIN_MOVEMENT = 0.03                     # Must be moving (not standing still)

UNSTABLE_COUNT_THRESHOLD = 4   # Need 4 consecutive unstable readings (0.4 seconds)
WARNING_DURATION = 2

# Data logging control
ENABLE_DATA_LOGGING = True
LOG_INTERVAL = 0.01
DATA_LOG_INTERVAL = 0.5
LOGGING_ACTIVE = False

# Colors
RED = (255, 0, 0)
YELLOW = (255, 255, 0)
GREEN = (0, 255, 0)
OFF = (0, 0, 0)

def check_serial_input():
    """Check for keyboard commands from serial"""
    if supervisor.runtime.serial_bytes_available:
        command = input().strip().lower()
        return command
    return None

def calculate_total_acceleration(x, y, z):
    """Calculate total acceleration magnitude"""
    return math.sqrt(x*x + y*y + z*z)

def calculate_mean(values):
    """Calculate mean of values"""
    return sum(values) / len(values) if values else 0

def calculate_std_dev(values):
    """Calculate standard deviation"""
    if len(values) < 2:
        return 0
    mean = calculate_mean(values)
    squared_diffs = [(v - mean) ** 2 for v in values]
    variance = sum(squared_diffs) / len(values)
    return math.sqrt(variance)

def analyze_simple_stability(total_g_buffer):
    if not total_g_buffer.is_full():
        return "STABLE", 0, 0  # last 0 is avg_change

    values = total_g_buffer.get_all()
    std_dev = calculate_std_dev(values)

    # Calculate smoothness / avg_change
    changes = [abs(values[i] - values[i-1]) for i in range(1, len(values))]
    avg_change = calculate_mean(changes)

    # Measure irregularity
    segment_size = 10
    segment_stds = []
    for i in range(0, len(values) - segment_size, segment_size):
        segment = values[i:i+segment_size]
        segment_stds.append(calculate_std_dev(segment))
    irregularity = calculate_std_dev(segment_stds) if len(segment_stds) > 1 else 0

    # Scoring
    instability_score = 0
    if avg_change > SMOOTHNESS_THRESHOLD:
        instability_score += 5
    if irregularity > IRREGULARITY_THRESHOLD:
        instability_score += 4
    if avg_change > SMOOTHNESS_THRESHOLD * 0.6:
        instability_score += 2
    if irregularity > IRREGULARITY_THRESHOLD * 0.6:
        instability_score += 2

    # Determine state
    if instability_score >= 5:
        return "UNSTABLE", instability_score, avg_change
    elif instability_score >= 3:
        return "WARNING", instability_score, avg_change
    else:
        return "STABLE", instability_score, avg_change

def detect_fall():
    """Monitor for fall events with prediction"""
    global LOGGING_ACTIVE

    freefall_start_time = None
    total_g_buffer = CircularBuffer(HISTORY_SIZE)
    unstable_count = 0
    last_state = "STABLE"
    warning_start_time = None
    last_ble_send_time = 0
    
    start_time = time.monotonic()
    last_log_time = 0
    logging_start_time = None
    
    print("\n=== CONTROLS ===")
    print("Type 's' and press ENTER to START logging")
    print("Type 'p' and press ENTER to PAUSE logging")
    print("Type 'r' and press ENTER to RESET timer")
    print("================\n")

    while True:
        command = check_serial_input()
        if command:
            if command == 's':
                LOGGING_ACTIVE = True
                logging_start_time = time.monotonic()
                print("\n### LOGGING STARTED ###")
                print("Time(s),Total_G,Instability_Score,State")
            elif command == 'p':
                LOGGING_ACTIVE = False
                print("\n### LOGGING PAUSED ###")
            elif command == 'r':
                start_time = time.monotonic()
                logging_start_time = None
                last_log_time = 0
                print("\n### TIMER RESET ###")
        
        if not ble.connected and not ble.advertising:
            ble.start_advertising(advertisement)

        if logging_start_time is not None:
            elapsed_time = time.monotonic() - logging_start_time
        else:
            elapsed_time = time.monotonic() - start_time

        x, y, z = accelerometer.acceleration
        total_g = calculate_total_acceleration(x, y, z) / 9.8
        total_g_buffer.append(total_g)

        # Simple stability analysis
        stability_state, score, avg_change = analyze_simple_stability(total_g_buffer)

        # Log data - keep it simple with print
        # After stability analysis, send BLE independently of logging
        if ble.connected and stability_state == "UNSTABLE":
            current_time = time.monotonic()
            if current_time - last_ble_send_time >= 1.0:
                message = f"INSTABILITY WARNING!{score}\n".encode()
                uart_service.write(message)
                last_ble_send_time = current_time

        # Keep logging block separate, only for serial data logging
        if ENABLE_DATA_LOGGING and LOGGING_ACTIVE and (elapsed_time - last_log_time >= DATA_LOG_INTERVAL):
            print(f"{elapsed_time:.2f},{avg_change:.3f},{score},{stability_state}")
            last_log_time = elapsed_time

        
        # Only send BLE if actually connected (don't spam it every loop)
        # This was causing freezing even without BLE connected!

        if stability_state == "UNSTABLE":
            unstable_count += 1
            if unstable_count >= UNSTABLE_COUNT_THRESHOLD:
                if last_state != "UNSTABLE":
                    pixel.fill(YELLOW)
                    # if ble.connected:
                       # pass
                        # uart_service.write(b"INSTABILITY WARNING!\n")
                    warning_start_time = time.monotonic()
                last_state = "UNSTABLE"
        elif stability_state == "WARNING":
            last_state = "WARNING"
        else:
            if last_state == "UNSTABLE" or last_state == "WARNING":
                if warning_start_time is None or (time.monotonic() - warning_start_time) > WARNING_DURATION:
                    pixel.fill(GREEN)
            unstable_count = 0
            last_state = "STABLE"
            warning_start_time = None

        # Fall detection
        if total_g < FREEFALL_THRESHOLD:
            if freefall_start_time is None:
                freefall_start_time = time.monotonic()
            else:
                freefall_duration = time.monotonic() - freefall_start_time
                print(freefall_duration >= FREEFALL_DURATION)
                if freefall_duration >= FREEFALL_DURATION:
                    impact_detected = wait_for_impact()
                    print(f"impact_detected:",  impact_detected)
                    if impact_detected:
                        pixel.fill(RED)
                        if ble.connected:
                            uart_service.write(b"FALL DETECTED!\n")  
                        time.sleep(LED_ALERT_DURATION)
                        pixel.fill(GREEN)
                        freefall_start_time = None
                        total_g_buffer.clear()
                        unstable_count = 0
                        last_state = "STABLE"
        else:
            if freefall_start_time is not None and total_g > FREEFALL_THRESHOLD + 0.2:
                freefall_start_time = None

        time.sleep(LOG_INTERVAL)

def wait_for_impact():
    """Wait briefly for impact after freefall"""
    start_time = time.monotonic()

    while time.monotonic() - start_time < 0.5:
        x, y, z = accelerometer.acceleration
        total_g = calculate_total_acceleration(x, y, z) / 9.8

        print(f"total_g: {total_g}, impact threshold {IMPACT_THRESHOLD}")
        

        if total_g > IMPACT_THRESHOLD:
            return True

        time.sleep(0.01)

    return False

print("===========================================")
print("Fall Detection - Simple & Effective")
print("===========================================")
print("BLE Name: FallDetector")
print("Strategy: Smoothness + Consistency Analysis")
print("Starting in 3 seconds...")
print("===========================================")
time.sleep(3)

pixel.fill(GREEN)
ble.start_advertising(advertisement)
detect_fall()