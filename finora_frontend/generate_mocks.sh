#!/bin/bash

# Script to generate mock files for testing
# This script generates the .mocks.dart files required by mockito

echo "🔨 Generating mock files for tests..."

# Navigate to the project directory
cd "$(dirname "$0")"

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Generate mocks
echo "🧪 Generating mocks..."
flutter pub run build_runner build --delete-conflicting-outputs

echo "✅ Mock generation complete!"
echo ""
echo "Generated files:"
echo "  - test/unit/features/authentication/domain/usecases/login_usecase_test.mocks.dart"
echo "  - test/unit/features/authentication/data/repositories/auth_repository_impl_test.mocks.dart"
echo "  - test/unit/features/authentication/presentation/bloc/auth_bloc_test.mocks.dart"
