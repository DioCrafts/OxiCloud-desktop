mod application;
mod domain;
mod infrastructure;
mod interfaces;

fn main() {
    // Setup the logging system
    tracing_subscriber::fmt::init();

    // Initialize the application with DI container
    interfaces::app::run();
}
