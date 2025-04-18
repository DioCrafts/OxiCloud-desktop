// This file was auto-generated as a stub
// Define UI components specific to the interface layer here

use dioxus::prelude::*;
// Scope debe importarse directamente o usarse como parte de dioxus_core

// Example component
pub fn AppBar(cx: Scope) -> Element {
    cx.render(rsx! {
        div { class: "app-bar",
            h1 { "OxiCloud Desktop" }
        }
    })
}