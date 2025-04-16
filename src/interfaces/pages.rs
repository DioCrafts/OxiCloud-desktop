use crate::interfaces::app::Route;
use crate::pages::LoginPage;
use crate::pages::FilesPage;
use crate::pages::EncryptionPage;
use crate::pages::PasswordRecoveryPage;
use crate::pages::SettingsPage;
use dioxus::prelude::*;
use dioxus_router::prelude::*;

/// Page component mappings for the router
pub fn pages(cx: Scope, route: Route) -> Element {
    match route {
        Route::Home {} => render! {
            Redirect { to: Route::Files {} }
        },
        Route::Login {} => render! { LoginPage {} },
        Route::Files {} => render! { FilesPage {} },
        Route::Settings {} => render! { 
            SettingsPage {}
        },
        Route::Encryption {} => render! { EncryptionPage {} },
        Route::PasswordRecovery {} => render! { 
            PasswordRecoveryPage {
                on_success: |_| {
                    let navigator = use_navigator(cx);
                    navigator.push(Route::Encryption {});
                },
                on_cancel: |_| {
                    let navigator = use_navigator(cx);
                    navigator.push(Route::Encryption {});
                }
            } 
        },
    }
}