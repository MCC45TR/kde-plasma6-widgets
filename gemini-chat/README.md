# Gemini-Kchat

Gemini-Kchat is a KDE Plasma plasmoid that integrates Google's Gemini AI directly into your desktop environment. Chat with Gemini using the Google AI Studio API without leaving your desktop.

## Features

- 👾 Direct integration with Google's Gemini AI
- 💬 Quick chat interface directly from your plasma panel
- 🔧 Multiple Gemini model selection (2.5 Flash, 2.5 Pro, 2.5 Flash-Lite, etc.)
- ♨️ Native KDE Plasma integration with system theme
- ⏱️ Fast and lightweight
- 🔧 Easy configuration

![Gemini-Kchat Screenshot](https://i.imgur.com/cuNddBl.png)

## Installation

### Method 1: Using .plasmoid file (Recommended)

1. Download the latest `gemini-kchat.plasmoid` file from the [Releases](../../releases) page
2. Install via command line:
   ```bash
   kpackagetool6 -i gemini-kchat.plasmoid
   ```
3. Right-click on your plasma panel → "Add Widgets..."
4. Search for "Gemini-Kchat" and add it to your panel

### Method 2: Manual Installation

1. Download the source code ZIP from the [Releases](../../releases) page
2. Extract and install:
   ```bash
   unzip gemini-kchat-v1.0.zip
   cd Gemini-Kchat
   kpackagetool6 -i contents --packageroot ~/.local/share/plasma/plasmoids/ -t Plasma/Applet
   ```
3. Right-click on your plasma panel → "Add Widgets..."
4. Search for "Gemini-Kchat" and add it to your panel

### Updating

To update to a newer version:
```bash
kpackagetool6 -u gemini-kchat.plasmoid
```

## Configuration

1. Right-click on the Gemini-Kchat widget
2. Select "Configure Gemini-Kchat..."
3. **Important**: Enter your Google AI Studio API key in the configuration dialog
4. Select your preferred Gemini model from the dropdown

![Configuration Settings](https://i.imgur.com/ao5Aw7T.png)

**Note**: The widget will not work until you configure your API key. You'll see a reminder message in the chat area if the API key is missing.

## Getting Your API Key

To use Gemini-Kchat, you need a Google AI Studio API key (it's free!):

1. Visit [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key" or "Get API Key"
4. Select or create a Google Cloud project
5. Copy the generated API key
6. Paste it in the Gemini-Kchat configuration settings

**Important**: Keep your API key secure and never share it publicly. The API key is stored locally in your KDE configuration.

## Usage

- Click on the Gemini-Kchat icon in your panel to open the chat interface
- Type your questions or messages and press Enter to send
- Chat history is maintained during the session

## Requirements

- KDE Plasma 6.0 or later
- Google AI Studio API key

## Development

Based on the original ChatQT plasmoid by Denys Madureira, modified and enhanced by kuro to work with Google's Gemini AI instead of local Ollama models.

## License

This project is licensed under the GNU Lesser General Public License v2.1 - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit pull requests, report issues, or suggest new features.

## Support

If you encounter any issues or have questions:
1. Check the existing issues on GitHub
2. Create a new issue with detailed information about your problem
3. Include your KDE Plasma version and system information

## Acknowledgments

- Original ChatQT plasmoid by [Denys Madureira](https://github.com/DenysMb/ChatQT-Plasmoid)
- Google AI Studio for providing the Gemini API
- KDE community for the excellent Plasma framework
