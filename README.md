# Enhanced Speech-to-Text for Flutter

Welcome to the Enhanced Speech-to-Text library for Flutter! This library extends the functionality of the native `speech_to_text` package to address common issues such as:

1. **Continuous Listening**: Supports uninterrupted listening sessions.
2. **Error Management**: Reduces instances of unexpected stops and improves error handling.
3. **State Management**: Ensures better state management for smoother performance.
4. **Consistent Stopping Mechanism**: Provides a reliable stopping mechanism during user interactions.

This library integrates seamlessly with Provider and SharedPreferences for state management and persistence.

## Features

- **Continuous Listening**: Keeps listening actively until explicitly stopped.
- **Improved Error Handling**: Handles errors gracefully without interrupting the user experience.
- **Enhanced State Management**: Utilizes Provider for effective state management.
- **Consistent User Interaction**: Ensures proper stopping and starting of the listening process.


## Contribution
I welcome contributions! Please read our contributing guidelines before submitting a pull request.

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Getting Started

To use this library, simply add the following dependency to your `pubspec.yaml`:

```yaml
dependencies:
  enhanced_speech_to_text:
    git:
      url: https://github.com/yourusername/enhanced_speech_to_text.git



