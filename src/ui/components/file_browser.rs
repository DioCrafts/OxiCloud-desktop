use std::sync::Arc;
use std::collections::HashMap;

use eframe::egui;
use egui::{Ui, Vec2, Color32, RichText, ScrollArea, SelectableLabel, Frame, Rounding, Stroke, SidePanel, TextEdit};
use crate::ui::theme::{OxiCloudColors, widgets, render_oxicloud_logo};
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
        let colors = OxiCloudColors::default();
        
        // Apply sidebar styling
        ui.style_mut().visuals.widgets.noninteractive.bg_fill = colors.sidebar_bg;
        ui.style_mut().visuals.widgets.inactive.bg_fill = colors.sidebar_bg;
        ui.style_mut().visuals.faint_bg_color = colors.sidebar_bg;
        
        // Storage usage indicator
        Frame::none()
            .fill(colors.active_item_bg)
            .rounding(Rounding::same(8.0))
            .inner_margin(15.0)
            .show(ui, |ui| {
                ui.vertical(|ui| {
                    ui.label(RichText::new("Storage").color(Color32::WHITE).size(14.0));
                    ui.add_space(10.0);
                    
                    // Storage bar
                    let storage_used_pct = 35.0; // Simulated
                    let (rect, _) = ui.allocate_exact_size(Vec2::new(ui.available_width(), 10.0), egui::Sense::hover());
                    
                    if ui.is_rect_visible(rect) {
                        // Background
                        ui.painter().rect_filled(
                            rect,
                            Rounding::same(5.0),
                            Color32::from_rgb(107, 126, 143) // #6b7e8f
                        );
                        
                        // Fill
                        ui.painter().rect_filled(
                            egui::Rect::from_min_size(
                                rect.min,
                                Vec2::new(rect.width() * storage_used_pct / 100.0, rect.height())
                            ),
                            Rounding::same(5.0),
                            colors.primary
                        );
                    }
                    
                    ui.add_space(10.0);
                    ui.label(RichText::new("3.5 GB of 10 GB used").color(Color32::WHITE).size(12.0));
                });
            });
        
        ui.add_space(20.0);
        
        ui.label(RichText::new("FOLDERS").color(Color32::from_rgb(180, 180, 180)).size(12.0));
        ui.add_space(10.0);
        
        // For now, we'll simulate a simple folder structure
        ScrollArea::vertical().show(ui, |ui| {
            // Root folder
            self.render_folder_tree_item(ui, "root", "All Files", 0);
            
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
        let colors = OxiCloudColors::default();
        
        let is_selected = self.current_folder_id == id;
        let has_children = id == "documents" || id == "photos"; // Simulated
        
        // Calculate the indentation
        let indent = indent_level as f32 * 20.0;
        
        // Folder item styling
        let item_bg = if is_selected { colors.active_item_bg } else { colors.sidebar_bg };
        let text_color = Color32::WHITE;
        
        // Create a clickable area for the entire row with proper styling
        let response = ui.horizontal(|ui| {
            // Apply styles
            ui.style_mut().visuals.widgets.noninteractive.bg_fill = item_bg;
            ui.style_mut().visuals.widgets.inactive.bg_fill = item_bg;
            ui.style_mut().visuals.widgets.inactive.fg_stroke = Stroke::new(1.0, text_color);
            
            ui.add_space(indent);
            
            // Folder icon (simplified cloud for root, folder for others)
            let icon_size = 16.0;
            let (icon_rect, _) = ui.allocate_exact_size(Vec2::splat(icon_size), egui::Sense::hover());
            
            if ui.is_rect_visible(icon_rect) {
                if id == "root" {
                    // Cloud icon for root
                    ui.painter().circle_filled(
                        icon_rect.center(),
                        icon_size / 2.0,
                        colors.primary
                    );
                } else {
                    // Folder icon for others
                    ui.painter().rect_filled(
                        egui::Rect::from_min_size(
                            icon_rect.min,
                            Vec2::new(icon_size, icon_size * 0.7)
                        ),
                        Rounding::same(3.0),
                        Color32::from_rgb(253, 203, 110) // Folder color
                    );
                    
                    // Folder tab
                    ui.painter().rect_filled(
                        egui::Rect::from_min_size(
                            icon_rect.min,
                            Vec2::new(icon_size, icon_size * 0.25)
                        ),
                        Rounding::same(3.0), 
                        Color32::from_rgb(233, 183, 90) // Darker color for tab
                    );
                }
            }
            
            ui.add_space(8.0);
            
            // Expand/collapse button for folders with children
            if has_children {
                let is_expanded = self.is_folder_expanded(id);
                let text = if is_expanded { "▼" } else { "►" };
                let expand_btn = ui.button(RichText::new(text).color(text_color).size(10.0));
                
                if expand_btn.clicked() {
                    self.toggle_folder_expanded(id);
                }
                
                ui.add_space(5.0);
            }
            
            // Folder name
            ui.label(RichText::new(name).color(text_color).size(14.0));
        });
        
        // Handle click on the entire row
        if response.response.clicked() {
            self.select_folder(id, name);
        }
        
        // Add hover styling
        if response.response.hovered() {
            ui.painter().rect_filled(
                response.response.rect,
                Rounding::same(0.0),
                if is_selected { colors.active_item_bg } else { colors.hover_bg }
            );
        }
    }
    
    /// Render the file list in the main panel
    pub fn render_file_list(&mut self, ui: &mut Ui, _app_state: &AppState) {
        let colors = OxiCloudColors::default();
        
        // Set main content background color
        ui.style_mut().visuals.widgets.noninteractive.bg_fill = colors.background;
        ui.style_mut().visuals.faint_bg_color = colors.background;
        
        ui.vertical(|ui| {
            // Breadcrumb navigation
            ui.add_space(10.0);
            Frame::none()
                .fill(colors.card_background)
                .inner_margin(15.0)
                .rounding(Rounding::same(8.0))
                .show(ui, |ui| {
                    ui.horizontal(|ui| {
                        // Home icon
                        let (home_rect, _) = ui.allocate_exact_size(Vec2::splat(20.0), egui::Sense::click());
                        if ui.is_rect_visible(home_rect) {
                            // Simple house icon
                            ui.painter().circle_filled(
                                home_rect.center(),
                                10.0,
                                colors.primary
                            );
                        }
                        
                        ui.add_space(5.0);
                        
                        // Path components
                        let path_parts: Vec<&str> = self.current_folder_path.split('/').filter(|p| !p.is_empty()).collect();
                        
                        if path_parts.is_empty() {
                            ui.label(RichText::new("Home").color(colors.primary).size(14.0));
                        } else {
                            ui.label(RichText::new("Home").color(colors.text_secondary).size(14.0));
                            
                            for (i, part) in path_parts.iter().enumerate() {
                                ui.label(RichText::new(" / ").color(colors.text_secondary).size(14.0));
                                
                                let is_last = i == path_parts.len() - 1;
                                let text_color = if is_last { colors.primary } else { colors.text_secondary };
                                ui.label(RichText::new(*part).color(text_color).size(14.0));
                            }
                        }
                    });
                });
            
            ui.add_space(20.0);
            
            // Folder heading
            ui.heading(RichText::new(&self.current_folder_name).size(24.0).color(colors.text_primary));
            
            ui.add_space(10.0);
            
            // File operations toolbar
            Frame::none()
                .fill(colors.card_background)
                .inner_margin(10.0)
                .rounding(Rounding::same(8.0))
                .show(ui, |ui| {
                    ui.horizontal(|ui| {
                        // Upload button
                        if widgets::primary_button(ui, "Upload").clicked() {
                            debug!("Upload button clicked");
                            // TODO: Implement file upload
                        }
                        
                        ui.add_space(10.0);
                        
                        // New Folder button
                        if widgets::secondary_button(ui, "New Folder").clicked() {
                            debug!("New Folder button clicked");
                            // TODO: Implement folder creation
                        }
                        
                        ui.add_space(10.0);
                        
                        // Refresh button
                        if widgets::secondary_button(ui, "Refresh").clicked() {
                            debug!("Refresh button clicked");
                            // TODO: Implement refresh
                        }
                        
                        // Search input on the right
                        ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                            let mut search_text = String::new();
                            let search = TextEdit::singleline(&mut search_text)
                                .hint_text("Search files...")
                                .desired_width(200.0);
                                
                            // Style the search box
                            ui.style_mut().visuals.widgets.inactive.bg_fill = Color32::from_rgb(240, 243, 247);
                            ui.style_mut().visuals.widgets.inactive.rounding = Rounding::same(50.0);
                            ui.add(search);
                            ui.reset_style();
                        });
                    });
                });
            
            ui.add_space(10.0);
            
            // Error message
            if let Some(error) = &self.error_message {
                Frame::none()
                    .fill(Color32::from_rgb(254, 226, 226)) // Light red
                    .inner_margin(10.0)
                    .rounding(Rounding::same(8.0))
                    .show(ui, |ui| {
                        ui.colored_label(colors.error, error);
                    });
                ui.add_space(10.0);
            }
            
            // File grid view
            Frame::none()
                .fill(colors.card_background)
                .inner_margin(20.0)
                .rounding(Rounding::same(8.0))
                .show(ui, |ui| {
                    // Display loading indicator
                    if self.is_loading {
                        ui.centered_and_justified(|ui| {
                            ui.label(RichText::new("Loading...").size(16.0).color(colors.text_secondary));
                        });
                        return;
                    }
                    
                    // File grid view (we'll use the file_card widget from our theme)
                    let available_width = ui.available_width();
                    let card_width = 160.0;
                    let spacing = 20.0;
                    
                    // Calculate number of cards per row
                    let cards_per_row = (available_width / (card_width + spacing)).floor().max(1.0) as usize;
                    
                    // For now, we'll simulate some files in the current folder
                    match self.current_folder_id.as_str() {
                        "root" => {
                            self.render_file_grid(ui, vec![
                                ("Documents", true),
                                ("Photos", true),
                                ("Music", true),
                                ("file1.txt", false),
                                ("file2.pdf", false),
                                ("image.jpg", false),
                            ], cards_per_row, card_width, spacing);
                        },
                        "documents" => {
                            self.render_file_grid(ui, vec![
                                ("Work", true),
                                ("Personal", true),
                                ("report.docx", false),
                                ("presentation.pptx", false),
                                ("spreadsheet.xlsx", false),
                            ], cards_per_row, card_width, spacing);
                        },
                        "photos" => {
                            self.render_file_grid(ui, vec![
                                ("Vacations", true),
                                ("Family", true),
                                ("photo1.jpg", false),
                                ("photo2.jpg", false),
                                ("photo3.jpg", false),
                            ], cards_per_row, card_width, spacing);
                        },
                        "music" => {
                            self.render_file_grid(ui, vec![
                                ("song1.mp3", false),
                                ("song2.mp3", false),
                                ("album.zip", false),
                            ], cards_per_row, card_width, spacing);
                        },
                        _ => {
                            ui.label("No files in this folder");
                        }
                    }
                });
        });
    }
    
    /// Render files in a grid layout
    fn render_file_grid(&mut self, ui: &mut Ui, items: Vec<(&str, bool)>, cards_per_row: usize, card_width: f32, spacing: f32) {
        let mut column = 0;
        
        ui.horizontal_wrapped(|ui| {
            ui.spacing_mut().item_spacing = Vec2::new(spacing, spacing);
            
            for (name, is_folder) in items {
                if column == 0 {
                    ui.add_space(0.0); // Force new row
                }
                
                // Render file/folder card using our custom widget
                let card = widgets::file_card(ui, name, if is_folder { "folder" } else { "file" }, is_folder);
                
                if card.clicked() {
                    if is_folder {
                        // Navigate to folder
                        let folder_id = match name {
                            "Documents" => "documents",
                            "Photos" => "photos",
                            "Music" => "music",
                            "Work" => "work",
                            "Personal" => "personal",
                            "Vacations" => "vacations",
                            "Family" => "family",
                            _ => "unknown"
                        };
                        self.select_folder(folder_id, name);
                    } else {
                        // File selection
                        debug!("Selected file: {}", name);
                    }
                }
                
                column = (column + 1) % cards_per_row;
            }
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