# Fail2Ban IP Analyzer

A Bash script to analyze banned IPs from Fail2Ban, fetch geolocation data from ipinfo.io, and generate detailed summaries with a special focus on Polish IPs.

## Features
- Retrieves banned IPs from Fail2Ban using `fail2ban-client banned`.
- Queries [ipinfo.io](https://ipinfo.io) for country, city, region, and organization details.
- Generates a general summary with IP counts by country.
- Provides a detailed summary of Polish IPs (country code "PL").
- Saves results to a timestamped file and displays them in the terminal.
- Includes error handling with retries and logging.

## Prerequisites
- **Bash**: Version 4.0+ (tested on 5.2.21)
- **Dependencies**:
  - `curl`: For API requests
  - `jq`: For JSON parsing
  - `sudo`: For running `fail2ban-client`
  - `fail2ban-client`: Part of Fail2Ban installation
- **ipinfo.io API Token**: Sign up at [ipinfo.io](https://ipinfo.io/signup) for a free token (50,000 requests/month).

## Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/KrystianGraba/fail2ban-ip-analyzer.git
   cd fail2ban-ip-analyzer
   ```
2. Make the script executable:
   ```bash
   chmod +x fail2ban_ip_analyzer.sh
   ```
3. Replace the `TOKEN` variable in the script with your ipinfo.io token:
   ```bash
   export IPINFO_TOKEN="your_token_here"
   ```

## Usage
Run the script with sudo privileges (required for `fail2ban-client`):
```bash
sudo ./fail2ban_ip_analyzer.sh
```

### Output
- **Terminal**: Displays processing status, Polish IP details, and full summaries.
- **File**: Saves all details to `fail2ban_analysis_YYYYMMDD_HHMMSS.txt` in the current directory.

#### Example Output
```
Starting Fail2Ban IP analysis...
Retrieving banned IPs...
Found 217 IPs to process

Processing IP: 103.112.131.68
Processing IP: 94.254.0.157
Polish IP Detected:
IP: 94.254.0.157
Country: PL
City: Warsaw
Region: Mazovia
Organization: AS12345 ISP Name

Generating summaries...
Analysis complete!
Results saved to: fail2ban_analysis_20250302_123456.txt

Full Results:
General Summary
===============
Total IPs analyzed: 217
IPs by Country:
CN: 50
US: 30
PL: 2
...

Polish IPs Summary
=================
Total Polish IPs: 2
IP | City | Region | Organization
--------------------------------
94.254.0.157 | Warsaw | Mazovia | AS12345 ISP Name
...
```

## Configuration
- `TOKEN`: Replace with your ipinfo.io token (default is a placeholder).
- `OUTPUT_FILE`: Customize the output file name or path if needed.

## Troubleshooting
- **Errors**: Check `/tmp/fail2ban_errors_*.log` for detailed logs if the script fails.
- **Permissions**: Ensure sudo access for `fail2ban-client`.
- **API Limits**: The free ipinfo.io tier has a 50,000 request/month limit; monitor usage for large IP lists.

## Contributing
1. Fork the repository.
2. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature
   ```
3. Commit changes:
   ```bash
   git commit -m "Add your feature"
   ```
4. Push to the branch:
   ```bash
   git push origin feature/your-feature
   ```
5. Open a Pull Request.

