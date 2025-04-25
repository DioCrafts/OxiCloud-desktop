use std::sync::Arc;
use std::collections::HashMap;

use eframe::egui;
use egui::{Ui, Vec2, Color32, RichText, ScrollArea, SelectableLabel};
use log::{info, debug, error};

use crate::domain::models::file::File;
use crate::domain::models::folder::Folder;
use crate::domain::repositories::file_repository::FileRepository;
use crate::domain::repositories::folder_repository::FolderRepository;
use crate::ui::app_state::AppState;

/// Component for browsing files and folders
pub struct FileBrowser {
    /// Repository for file operations
    file_repository: Arc<dyn FileRepository>,
    
    /// Repository for folder operations
    folder_repository: Arc<dyn FolderRepository>,
    
    /// Current folder ID
    current_folder_id: String,
    
    /// Current folder path
    current_folder_path: String,
    
    /// Current folder name
    current_folder_name: String,
    
    /// Cached folders for tree view
    folders_cache: HashMap<String, Vec<Folder>>,
    
    /// Cached files for current folder
    files_cache: Vec<File>,
    
    /// Expanded folder IDs in the tree view
    expanded_folders: HashMap<String, bool>,
    
    /// Selected file ID
    selected_file_id: Option<String>,
    
    /// Loading state
    is_loading: bool,
    
    /// Error message
    error_message: Option<String>,
}

impl FileBrowser {
    /// Create a new file browser
    pub fn new(
        file_repository: Arc<dyn FileRepository>,
        folder_repository: Arc<dyn FolderRepository>
    ) -> Self {
        Self {
            file_repository,
            folder_repository,
            current_folder_id: "root".to_string(),
            current_folder_path: "/".to_string(),
            current_folder_name: "Root".to_string(),
            folders_cache: HashMap::new(),
            files_cache: Vec::new(),
            expanded_folders: HashMap::new(),
            selected_file_id: None,
            is_loading: false,
            error_message: None,
        }
    }
    
    /// Render the folder tree in the left panel
    pub fn render_folder_tree(&mut self, ui: &mut Ui) {
        // For now, we'll simulate a simple folder structure
        ScrollArea::vertical().show(ui, |ui| {
            // Root folder
            self.render_folder_tree_item(ui, "root", "Root", 0);
            
            // First level folders (simulated)
            self.render_folder_tree_item(ui, "documents", "Documents", 1);
            self.render_folder_tree_item(ui, "photos", "Photos", 1);
            self.render_folder_tree_item(ui, "music", "Music", 1);
            
            // Second level folders (simulated)
            if self.is_folder_expanded("documents") {
                self.render_folder_tree_item(ui, "work", "Work", 2);
                self.render_folder_tree_item(ui, "personal", "Personal", 2);
            }
            
            if self.is_folder_expanded("photos") {
                self.render_folder_tree_item(ui, "vacations", "Vacations", 2);
                self.render_folder_tree_item(ui, "family", "Family", 2);
            }
        });
    }
    
    /// Render a folder tree item
    fn render_folder_tree_item(&mut self, ui: &mut Ui, id: &str, name: &str, indent_level: usize) {
        ui.horizontal(|ui| {
            ui.add_space(indent_level as f32 * 20.0);
            
            let has_children = id == "documents" || id == "photos"; // Simulated
            
            // Expand/collapse button
            if has_children {
                let is_expanded = self.is_folder_expanded(id);
                let text = if is_expanded { "▼" } else { "►" };
                if ui.button(text).clicked() {
                    self.toggle_folder_expanded(id);
                }
            } else {
                ui.add_space(20.0); // Same space as the button
            }
            
            // Folder name with selection
            let is_selected = self.current_folder_id == id;
            if ui.add(SelectableLabel::new(is_selected, RichText::new(name))).clicked() {
                self.select_folder(id, name);
            }
        });
    }
    
    /// Render the file list in the main panel
    pub fn render_file_list(&mut self, ui: &mut Ui, _app_state: &AppState) {
        ui.vertical(|ui| {
            // Current folder path
            ui.horizontal(|ui| {
                ui.label(RichText::new(&self.current_folder_path).size(16.0));
            });
            
            ui.separator();
            
            // File operations toolbar
            ui.horizontal(|ui| {
                if ui.button("Upload").clicked() {
                    debug!("Upload button clicked");
                    // TODO: Implement file upload
                }
                
                if ui.button("New Folder").clicked() {
                    debug!("New Folder button clicked");
                    // TODO: Implement folder creation
                }
                
                if ui.button("Refresh").clicked() {
                    debug!("Refresh button clicked");
                    // TODO: Implement refresh
                }
            });
            
            ui.separator();
            
            // Error message
            if let Some(error) = &self.error_message {
                ui.colored_label(Color32::RED, error);
                ui.separator();
            }
            
            // File list
            ScrollArea::vertical().show(ui, |ui| {
                // Display loading indicator
                if self.is_loading {
                    ui.label("Loading...");
                    return;
                }
                
                // For now, we'll simulate some files in the current folder
                self.render_simulated_files(ui);
            });
        });
    }
    
    /// Render simulated files (temporary implementation)
    fn render_simulated_files(&mut self, ui: &mut Ui) {
        // Header row
        ui.horizontal(|ui| {
            let name_column_width = 200.0;
            let size_column_width = 100.0;
            let modified_column_width = 150.0;
            let type_column_width = 100.0;
            
            ui.add_sized([name_column_width, 20.0], egui::Label::new(RichText::new("Name").strong()));
            ui.add_sized([size_column_width, 20.0], egui::Label::new(RichText::new("Size").strong()));
            ui.add_sized([modified_column_width, 20.0], egui::Label::new(RichText::new("Modified").strong()));
            ui.add_sized([type_column_width, 20.0], egui::Label::new(RichText::new("Type").strong()));
        });
        
        ui.separator();
        
        // Show some simulated files based on current folder
        match self.current_folder_id.as_str() {
            "root" => {
                self.render_file_item(ui, "file1.txt", "10 KB", "Yesterday", "Text");
                self.render_file_item(ui, "file2.pdf", "256 KB", "Last week", "PDF");
                self.render_file_item(ui, "image.jpg", "1.2 MB", "2 days ago", "Image");
            },
            "documents" => {
                self.render_file_item(ui, "report.docx", "45 KB", "Yesterday", "Word");
                self.render_file_item(ui, "presentation.pptx", "2.1 MB", "3 days ago", "PowerPoint");
                self.render_file_item(ui, "spreadsheet.xlsx", "156 KB", "Last week", "Excel");
            },
            "photos" => {
                self.render_file_item(ui, "photo1.jpg", "3.2 MB", "Last month", "Image");
                self.render_file_item(ui, "photo2.jpg", "2.8 MB", "Last month", "Image");
                self.render_file_item(ui, "photo3.jpg", "4.1 MB", "Last month", "Image");
            },
            "music" => {
                self.render_file_item(ui, "song1.mp3", "4.5 MB", "2 months ago", "Audio");
                self.render_file_item(ui, "song2.mp3", "5.2 MB", "2 months ago", "Audio");
                self.render_file_item(ui, "album.zip", "45.6 MB", "2 months ago", "Archive");
            },
            _ => {
                ui.label("No files in this folder");
            }
        }
    }
    
    /// Render a file item in the list
    fn render_file_item(&mut self, ui: &mut Ui, name: &str, size: &str, modified: &str, file_type: &str) {
        ui.horizontal(|ui| {
            let name_column_width = 200.0;
            let size_column_width = 100.0;
            let modified_column_width = 150.0;
            let type_column_width = 100.0;
            
            ui.add_sized([name_column_width, 20.0], egui::Label::new(name));
            ui.add_sized([size_column_width, 20.0], egui::Label::new(size));
            ui.add_sized([modified_column_width, 20.0], egui::Label::new(modified));
            ui.add_sized([type_column_width, 20.0], egui::Label::new(file_type));
        });
    }
    
    /// Check if a folder is expanded
    fn is_folder_expanded(&self, id: &str) -> bool {
        *self.expanded_folders.get(id).unwrap_or(&false)
    }
    
    /// Toggle the expanded state of a folder
    fn toggle_folder_expanded(&mut self, id: &str) {
        let is_expanded = self.is_folder_expanded(id);
        self.expanded_folders.insert(id.to_string(), !is_expanded);
    }
    
    /// Select a folder
    fn select_folder(&mut self, id: &str, name: &str) {
        debug!("Selecting folder: {} ({})", name, id);
        
        self.current_folder_id = id.to_string();
        self.current_folder_name = name.to_string();
        
        // Update the path
        match id {
            "root" => self.current_folder_path = "/".to_string(),
            "documents" | "photos" | "music" => self.current_folder_path = format!("/{}", name),
            _ => {
                // For nested folders, construct the path based on parent
                if id == "work" || id == "personal" {
                    self.current_folder_path = format!("/Documents/{}", name);
                } else if id == "vacations" || id == "family" {
                    self.current_folder_path = format!("/Photos/{}", name);
                }
            }
        }
        
        // In a real implementation, we would load the files for this folder
        // self.load_files_for_folder(id);
    }
    
    /// Load files for a folder
    async fn load_files_for_folder(&mut self, folder_id: &str) {
        self.is_loading = true;
        self.error_message = None;
        
        match self.file_repository.get_files_in_folder(folder_id).await {
            Ok(files) => {
                self.files_cache = files;
                self.is_loading = false;
            },
            Err(e) => {
                error!("Failed to load files: {}", e);
                self.error_message = Some(format!("Failed to load files: {}", e));
                self.is_loading = false;
            }
        }
    }
    
    /// Load folders for the folder tree
    async fn load_folders(&mut self) {
        self.is_loading = true;
        self.error_message = None;
        
        // Load root folder first
        match self.folder_repository.get_root_folder().await {
            Ok(root) => {
                // Then load its subfolders
                match self.folder_repository.get_subfolders(&root.id).await {
                    Ok(subfolders) => {
                        self.folders_cache.insert("root".to_string(), subfolders);
                        self.is_loading = false;
                    },
                    Err(e) => {
                        error!("Failed to load subfolders: {}", e);
                        self.error_message = Some(format!("Failed to load folders: {}", e));
                        self.is_loading = false;
                    }
                }
            },
            Err(e) => {
                error!("Failed to load root folder: {}", e);
                self.error_message = Some(format!("Failed to load root folder: {}", e));
                self.is_loading = false;
            }
        }
    }
}