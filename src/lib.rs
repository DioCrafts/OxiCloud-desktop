// Export modules for testing and library usage
pub mod application;
pub mod domain;
pub mod infrastructure;
pub mod interfaces;
pub mod components;
pub mod pages;

// Re-export main function
pub use crate::interfaces::app::run;