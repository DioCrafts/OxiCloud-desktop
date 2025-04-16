use dioxus::prelude::*;
use crate::domain::entities::recovery::{RecoveryMethod, SecurityQuestion};
use crate::application::ports::encryption_port::EncryptionPort;
use std::sync::Arc;
use tracing::{info, error};

enum RecoveryStep {
    ChooseMethod,
    SecurityQuestions,
    RecoveryKey,
    SetNewPassword,
    Success,
    Failed(String),
}

#[derive(Props)]
pub struct PasswordRecoveryProps {
    #[props(optional)]
    on_success: Option<Callback<()>>,
    #[props(optional)]
    on_cancel: Option<Callback<()>>,
}

pub fn PasswordRecoveryPage(cx: Scope<PasswordRecoveryProps>) -> Element {
    let encryption_service = use_shared_state::<Arc<dyn EncryptionPort>>(cx).unwrap();
    
    let step = use_state(cx, || RecoveryStep::ChooseMethod);
    let selected_method = use_state(cx, || None::<RecoveryMethod>);
    let security_questions = use_state(cx, || Vec::<SecurityQuestion>::new());
    let question_answers = use_state(cx, || Vec::<(String, String)>::new());
    let recovery_key_id = use_state(cx, || String::new());
    let verification_code = use_state(cx, || String::new());
    let new_password = use_state(cx, || String::new());
    let confirm_password = use_state(cx, || String::new());
    let is_loading = use_state(cx, || false);
    
    // Back button handler
    let go_back = |_| {
        match *step.get() {
            RecoveryStep::SecurityQuestions | RecoveryStep::RecoveryKey => {
                step.set(RecoveryStep::ChooseMethod);
            },
            RecoveryStep::SetNewPassword => {
                match *selected_method.get() {
                    Some(RecoveryMethod::SecurityQuestions) => step.set(RecoveryStep::SecurityQuestions),
                    Some(RecoveryMethod::BackupKeyFile) |
                    Some(RecoveryMethod::PrintedRecoveryCode) |
                    Some(RecoveryMethod::TrustedDevice) => step.set(RecoveryStep::RecoveryKey),
                    None => step.set(RecoveryStep::ChooseMethod),
                }
            },
            RecoveryStep::Failed(_) => {
                step.set(RecoveryStep::ChooseMethod);
            },
            _ => {}
        }
    };
    
    // Cancel button handler
    let cancel = |_| {
        if let Some(callback) = &cx.props.on_cancel {
            callback.call(());
        }
    };
    
    // Use a different render for each step
    match step.get() {
        RecoveryStep::ChooseMethod => {
            cx.render(rsx! {
                div { class: "recovery-container",
                    h2 { "Recover Encryption Password" }
                    p { "Please select a recovery method:" }
                    
                    div { class: "recovery-methods",
                        button {
                            class: "method-button",
                            onclick: move |_| {
                                selected_method.set(Some(RecoveryMethod::SecurityQuestions));
                                step.set(RecoveryStep::SecurityQuestions);
                            },
                            "Security Questions"
                        }
                        button {
                            class: "method-button",
                            onclick: move |_| {
                                selected_method.set(Some(RecoveryMethod::PrintedRecoveryCode));
                                step.set(RecoveryStep::RecoveryKey);
                            },
                            "Recovery Key"
                        }
                        button {
                            class: "method-button",
                            onclick: move |_| {
                                selected_method.set(Some(RecoveryMethod::BackupKeyFile));
                                
                                // This would open a file dialog and then proceed to password reset
                                // For now, we'll just go to the recovery key screen
                                step.set(RecoveryStep::RecoveryKey);
                            },
                            "Backup Key File"
                        }
                    }
                    
                    div { class: "button-row",
                        button {
                            class: "cancel-button",
                            onclick: cancel,
                            "Cancel"
                        }
                    }
                }
            })
        },
        RecoveryStep::SecurityQuestions => {
            let verify_answers = move |_| {
                to_owned![step, is_loading, question_answers, encryption_service];
                
                cx.spawn(async move {
                    is_loading.set(true);
                    
                    // This would normally call the recovery service
                    // For this MVP, we'll simulate the verification with a delay
                    tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
                    
                    // Simulate successful verification
                    step.set(RecoveryStep::SetNewPassword);
                    is_loading.set(false);
                });
            };
            
            cx.render(rsx! {
                div { class: "recovery-container",
                    h2 { "Answer Security Questions" }
                    p { "Please answer at least 2 security questions correctly:" }
                    
                    div { class: "security-questions",
                        // For demo purposes, showing static questions
                        div { class: "question-item",
                            label { "What was your first pet's name?" }
                            input {
                                r#type: "text",
                                placeholder: "Answer",
                                oninput: move |evt| {
                                    let mut answers = question_answers.get().clone();
                                    if answers.is_empty() {
                                        answers.push(("1".to_string(), evt.value.clone()));
                                    } else {
                                        answers[0] = ("1".to_string(), evt.value.clone());
                                    }
                                    question_answers.set(answers);
                                }
                            }
                        }
                        
                        div { class: "question-item",
                            label { "What was the name of your first school?" }
                            input {
                                r#type: "text",
                                placeholder: "Answer",
                                oninput: move |evt| {
                                    let mut answers = question_answers.get().clone();
                                    if answers.len() < 2 {
                                        answers.push(("2".to_string(), evt.value.clone()));
                                    } else {
                                        answers[1] = ("2".to_string(), evt.value.clone());
                                    }
                                    question_answers.set(answers);
                                }
                            }
                        }
                        
                        div { class: "question-item",
                            label { "What is your favorite color?" }
                            input {
                                r#type: "text",
                                placeholder: "Answer",
                                oninput: move |evt| {
                                    let mut answers = question_answers.get().clone();
                                    if answers.len() < 3 {
                                        answers.push(("3".to_string(), evt.value.clone()));
                                    } else {
                                        answers[2] = ("3".to_string(), evt.value.clone());
                                    }
                                    question_answers.set(answers);
                                }
                            }
                        }
                    }
                    
                    div { class: "button-row",
                        button {
                            class: "back-button",
                            onclick: go_back,
                            "Back"
                        }
                        
                        button {
                            class: "next-button",
                            disabled: *is_loading.get() || question_answers.get().len() < 2,
                            onclick: verify_answers,
                            if *is_loading.get() { "Verifying..." } else { "Next" }
                        }
                    }
                }
            })
        },
        RecoveryStep::RecoveryKey => {
            let verify_key = move |_| {
                to_owned![step, is_loading, recovery_key_id, verification_code, encryption_service];
                
                cx.spawn(async move {
                    is_loading.set(true);
                    
                    // This would normally call the recovery service
                    // For this MVP, we'll simulate the verification with a delay
                    tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
                    
                    // Simulate successful verification
                    step.set(RecoveryStep::SetNewPassword);
                    is_loading.set(false);
                });
            };
            
            cx.render(rsx! {
                div { class: "recovery-container",
                    h2 { "Enter Recovery Key" }
                    p { "Please enter your recovery key ID and verification code:" }
                    
                    div { class: "recovery-key-form",
                        div { class: "form-group",
                            label { "Recovery Key ID" }
                            input {
                                r#type: "text",
                                placeholder: "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
                                value: recovery_key_id.get(),
                                oninput: move |evt| recovery_key_id.set(evt.value.clone())
                            }
                        }
                        
                        div { class: "form-group",
                            label { "Verification Code" }
                            input {
                                r#type: "text",
                                placeholder: "XXXX-XXXX-XXXX-XXXX",
                                value: verification_code.get(),
                                oninput: move |evt| verification_code.set(evt.value.clone())
                            }
                        }
                    }
                    
                    div { class: "button-row",
                        button {
                            class: "back-button",
                            onclick: go_back,
                            "Back"
                        }
                        
                        button {
                            class: "next-button",
                            disabled: *is_loading.get() || recovery_key_id.get().is_empty() || verification_code.get().is_empty(),
                            onclick: verify_key,
                            if *is_loading.get() { "Verifying..." } else { "Next" }
                        }
                    }
                }
            })
        },
        RecoveryStep::SetNewPassword => {
            let reset_password = move |_| {
                to_owned![step, is_loading, new_password, confirm_password, encryption_service];
                
                cx.spawn(async move {
                    is_loading.set(true);
                    
                    // Verify passwords match
                    if new_password.get() != confirm_password.get() {
                        step.set(RecoveryStep::Failed("Passwords do not match".to_string()));
                        is_loading.set(false);
                        return;
                    }
                    
                    // This would normally call the recovery service
                    // For this MVP, we'll simulate the reset with a delay
                    tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
                    
                    // Simulate successful reset
                    step.set(RecoveryStep::Success);
                    is_loading.set(false);
                });
            };
            
            cx.render(rsx! {
                div { class: "recovery-container",
                    h2 { "Set New Password" }
                    p { "Please enter and confirm your new encryption password:" }
                    
                    div { class: "password-form",
                        div { class: "form-group",
                            label { "New Password" }
                            input {
                                r#type: "password",
                                placeholder: "Enter new password",
                                value: new_password.get(),
                                oninput: move |evt| new_password.set(evt.value.clone())
                            }
                        }
                        
                        div { class: "form-group",
                            label { "Confirm Password" }
                            input {
                                r#type: "password",
                                placeholder: "Confirm new password",
                                value: confirm_password.get(),
                                oninput: move |evt| confirm_password.set(evt.value.clone())
                            }
                        }
                    }
                    
                    div { class: "button-row",
                        button {
                            class: "back-button",
                            onclick: go_back,
                            "Back"
                        }
                        
                        button {
                            class: "reset-button",
                            disabled: *is_loading.get() || new_password.get().len() < 8 || confirm_password.get() != *new_password.get(),
                            onclick: reset_password,
                            if *is_loading.get() { "Resetting..." } else { "Reset Password" }
                        }
                    }
                }
            })
        },
        RecoveryStep::Success => {
            let finish = move |_| {
                if let Some(callback) = &cx.props.on_success {
                    callback.call(());
                }
            };
            
            cx.render(rsx! {
                div { class: "recovery-container success",
                    h2 { "Password Reset Successful" }
                    p { "Your encryption password has been reset successfully." }
                    p { "You can now access your encrypted files with your new password." }
                    
                    div { class: "button-row",
                        button {
                            class: "finish-button",
                            onclick: finish,
                            "Finish"
                        }
                    }
                }
            })
        },
        RecoveryStep::Failed(error) => {
            cx.render(rsx! {
                div { class: "recovery-container error",
                    h2 { "Password Reset Failed" }
                    p { "There was a problem resetting your password:" }
                    p { class: "error-message", "{error}" }
                    
                    div { class: "button-row",
                        button {
                            class: "back-button",
                            onclick: go_back,
                            "Try Again"
                        }
                        
                        button {
                            class: "cancel-button",
                            onclick: cancel,
                            "Cancel"
                        }
                    }
                }
            })
        },
    }
}