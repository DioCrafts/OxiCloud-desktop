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
        Route::Home {} => cx.render(rsx! {
            Outlet { route: Route::Files {} }
        }),
        Route::Login {} => cx.render(rsx! { LoginPage {} }),
        Route::Files {} => cx.render(rsx! { FilesPage {} }),
        Route::Settings {} => cx.render(rsx! { 
            SettingsPage {}
        }),
        Route::Encryption {} => cx.render(rsx! { EncryptionPage {} }),
        Route::PasswordRecovery {} => {
            let navigator = use_navigator(cx);
            cx.render(rsx! { 
                PasswordRecoveryPage {
                    on_success: move |_| {
                        navigator.push(Route::Encryption {});
                    },
                    on_cancel: move |_| {
                        navigator.push(Route::Encryption {});
                    }
                } 
            })
        },
    }
}