#!/usr/bin/env python3

import os

def remove_json_files(directory):
    """Recursively find and delete all .json files in the given directory."""
    for root, dirs, files in os.walk(directory):
        for file_name in files:
            if file_name.endswith('.json'):
                file_path = os.path.join(root, file_name)
                print(f"Deleting: {file_path}")
                os.remove(file_path)

if __name__ == "__main__":
    directory_to_scan = input("Enter the path of the directory to scan for .json files: ").strip()
    
    # Check if the entered path is a valid directory
    if os.path.isdir(directory_to_scan):
        confirmation = input(f"Are you sure you want to delete all .json files in '{directory_to_scan}'? (y/n): ").strip().lower()
        if confirmation == 'y':
            remove_json_files(directory_to_scan)
            print("All .json files have been deleted.")
        else:
            print("Operation canceled.")
    else:
        print("Error: The provided path is not a valid directory.")
