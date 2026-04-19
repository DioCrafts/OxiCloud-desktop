# OxiCloud Desktop Client

.PHONY: get gen clean run-web run-macos run-linux run-windows run-ios run-android

get:
	flutter pub get

gen:
	dart run build_runner build --delete-conflicting-outputs

watch:
	dart run build_runner watch --delete-conflicting-outputs

clean:
	flutter clean && flutter pub get

run-web:
	flutter run -d chrome

run-macos:
	flutter run -d macos

run-linux:
	flutter run -d linux

run-windows:
	flutter run -d windows

run-ios:
	flutter run -d ios

run-android:
	flutter run -d android

build-apk:
	flutter build apk --release

build-ios:
	flutter build ios --release

build-macos:
	flutter build macos --release

build-linux:
	flutter build linux --release

build-windows:
	flutter build windows --release

test:
	flutter test

analyze:
	flutter analyze
