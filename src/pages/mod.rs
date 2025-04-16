pub mod login;
pub mod files;
pub mod encryption;
pub mod password_recovery;
pub mod settings;

// Re-export pages
pub use login::LoginPage;
pub use files::FilesPage;
pub use encryption::EncryptionPage;
pub use password_recovery::PasswordRecoveryPage;
pub use settings::SettingsPage;