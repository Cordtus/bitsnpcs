"""
===============================
Log File Analyzer - Instructions
===============================

This script allows you to analyze log files by grouping similar log entries, filtering out repetitive patterns, and exploring specific log groups.

How to Use:
-----------
1. **Run the Script**:
   - When you run the script, it will first prompt you to enter the path to the log file you want to analyze.
   - Example: `/path/to/your/logfile.txt`

2. **Common Log Messages**:
   - After reading the log file, the script will display a list of common log messages, grouped by similarity.
   - Each group is displayed with a number and the count of occurrences.

3. **Interactive Options**:
   - You can choose to either:
     - **Filter out** a repetitive log pattern if you no longer want to see it.
     - **Explore** a specific log group in detail by viewing all individual logs that match that pattern.

4. **Filtering Logs**:
   - To filter out a specific pattern (e.g., repetitive logs), enter the number corresponding to that pattern and choose `(f)` for filter.
   - The script will remove all logs matching that pattern and re-run with the remaining logs.

5. **Exploring Logs**:
   - To explore a specific log group in detail, enter the number corresponding to that pattern and choose `(e)` for explore.
   - The script will display all individual logs in that group.
   - Press `Enter` to return to the main menu after viewing the logs.

6. **Exit**:
   - To exit the script at any time, simply type `q` when prompted.

Error Handling:
---------------
- If an invalid file path is entered, an error message will be displayed. Please ensure that the file path is correct.
- If an invalid choice is entered during filtering or exploration, you will be prompted again.

"""

import re
from collections import defaultdict

# Define initial regex patterns for common dynamic parts of log messages
dynamic_patterns = [
    r'height=\d+',                   # Block heights
    r'peer=[a-f0-9]+',                # Peer IDs
    r'block_app_hash=[A-F0-9]+',      # Block app hashes
    r'nonce=\d+',                     # Nonce values
    r'priority=\d+',                  # Priority values
    r'latency_ms=\d+',                # Latency in milliseconds
    r'tx=[A-F0-9]+',                  # Transaction IDs
    r'address=[a-fA-F0-9]+',          # Addresses
    r'tx_height=\d+',                 # Transaction heights
    r'tx_timestamp=[\d\-T:.Z]+',      # Timestamps in transactions
    r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d+Z',  # ISO timestamps
]

# Function to detect new dynamic values in log messages and add them to the pattern list
def detect_new_dynamic_patterns(message):
    # Detect IP addresses (IPv4)
    ip_pattern = re.compile(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b')
    if ip_pattern.search(message):
        dynamic_patterns.append(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b')

    # Detect port numbers (common range 1024-65535)
    port_pattern = re.compile(r':\d{4,5}')
    if port_pattern.search(message):
        dynamic_patterns.append(r':\d{4,5}')

    # Detect other peer IDs or hashes (hexadecimal strings)
    hex_pattern = re.compile(r'\b[a-fA-F0-9]{40,64}\b')
    if hex_pattern.search(message):
        dynamic_patterns.append(r'\b[a-fA-F0-9]{40,64}\b')

# Function to normalize log messages by replacing detected dynamic parts with placeholders
def normalize_message(message):
    detect_new_dynamic_patterns(message)  # Learn new patterns from the current message
    
    for pattern in dynamic_patterns:
        message = re.sub(pattern, '<DYNAMIC>', message)
    
    return message

# Function to parse logs and count occurrences of unique (normalized) messages
def parse_logs(log_file, exclude_patterns):
    log_summary = defaultdict(int)
    original_logs = defaultdict(list)

    with open(log_file, 'r') as file:
        for line in file:
            message = line.strip()
            
            # Normalize the message to group similar logs together
            normalized_message = normalize_message(message)

            # Skip any messages matching the exclude patterns
            if any(re.search(pattern, normalized_message) for pattern in exclude_patterns):
                continue

            # Count occurrences of each unique (normalized) message and store original logs
            log_summary[normalized_message] += 1
            original_logs[normalized_message].append(line.strip())

    return log_summary, original_logs

# Function to display logs and allow filtering or exploration
def interactive_filter():
    
    # Prompt user to enter the path to the log file
    log_file_path = input("Please enter the path to your log file: ")

    exclude_patterns = []

    while True:
        try:
            # Parse the logs and get a summary of unique (normalized) messages
            log_summary, original_logs = parse_logs(log_file_path, exclude_patterns)

            # Sort by frequency and display the most common messages at the bottom
            sorted_logs = sorted(log_summary.items(), key=lambda x: x[1])

            print("\n=== Common Log Messages ===")
            for i, (message, count) in enumerate(sorted_logs):
                print(f"[{i}] {count} occurrences: {message}")

            if not sorted_logs:
                print("No more logs to display.")
                break

            # Ask user if they want to filter out any message patterns or explore a specific log group
            choice = input("\nEnter the number of the message pattern to filter out or explore (or 'q' to quit): ")

            if choice.lower() == 'q':
                break

            try:
                choice_idx = int(choice)
                if 0 <= choice_idx < len(sorted_logs):
                    selected_message = sorted_logs[choice_idx][0]

                    # Ask whether to filter or explore this specific log group
                    action_choice = input(f"\nDo you want to (f)ilter out or (e)xplore this log group? ")

                    if action_choice.lower() == 'f':
                        exclude_patterns.append(re.escape(selected_message))
                        print(f"Filtered out: {selected_message}")
                    elif action_choice.lower() == 'e':
                        print(f"\n=== Exploring Logs for Pattern: {selected_message} ===")
                        for idx, original_log in enumerate(original_logs[selected_message]):
                            print(f"{idx + 1}: {original_log}")
                        
                        input("\nPress Enter to return to the main menu.")
                    else:
                        print("Invalid choice. Please enter 'f' for filter or 'e' for explore.")
                else:
                    print("Invalid choice. Please select a valid number.")
            except ValueError:
                print("Invalid input. Please enter a number or 'q'.")
        
        except FileNotFoundError:
            print(f"Error: The file '{log_file_path}' was not found. Please check your path and try again.")
            break

# Run the interactive filtering process with file path prompt at start
interactive_filter()
