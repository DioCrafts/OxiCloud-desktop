use egui::{Color32, Visuals, Rounding, Stroke, FontId, FontFamily, Style, TextStyle, TextEdit};
use egui::style::{WidgetVisuals, Selection};

/// OxiCloud theme colors
pub struct OxiCloudColors {
    /// Primary brand color
    pub primary: Color32,
    /// Background color
    pub background: Color32,
    /// Card background color
    pub card_background: Color32,
    /// Text primary color
    pub text_primary: Color32,
    /// Text secondary color
    pub text_secondary: Color32,
    /// Separator color
    pub separator: Color32,
    /// Sidebar background color
    pub sidebar_bg: Color32,
    /// Sidebar text color
    pub sidebar_text: Color32,
    /// Active item background
    pub active_item_bg: Color32,
    /// Hover background
    pub hover_bg: Color32,
    /// Error color
    pub error: Color32,
    /// Success color
    pub success: Color32,
}

impl Default for OxiCloudColors {
    fn default() -> Self {
        Self {
            // Primary brand color from OxiCloud
            primary: Color32::from_rgb(255, 94, 58),        // #ff5e3a
            background: Color32::from_rgb(245, 247, 250),   // #f5f7fa
            card_background: Color32::WHITE,                // #ffffff
            text_primary: Color32::from_rgb(45, 55, 72),    // #2d3748
            text_secondary: Color32::from_rgb(113, 128, 150), // #718096
            separator: Color32::from_rgb(230, 230, 230),    // #e6e6e6
            sidebar_bg: Color32::from_rgb(42, 48, 66),      // #2a3042
            sidebar_text: Color32::WHITE,                   // #ffffff
            active_item_bg: Color32::from_rgb(55, 78, 101), // #374e65
            hover_bg: Color32::from_rgb(58, 65, 87),        // #3a4157
            error: Color32::from_rgb(185, 28, 28),          // #b91c1c
            success: Color32::from_rgb(21, 128, 61),        // #15803d
        }
    }
}

/// Apply OxiCloud theme to egui context
pub fn apply_oxicloud_theme(ctx: &egui::Context) {
    let colors = OxiCloudColors::default();
    
    // Create our custom visuals
    let mut visuals = Visuals::light();
    
    // Customize the visuals to match OxiCloud web
    visuals.widgets.noninteractive.bg_fill = colors.background;
    visuals.widgets.noninteractive.fg_stroke = Stroke::new(1.0, colors.text_primary);
    
    // Interactive widgets (buttons, etc.)
    visuals.widgets.inactive.bg_fill = colors.card_background;
    visuals.widgets.inactive.fg_stroke = Stroke::new(1.0, colors.text_primary);
    visuals.widgets.inactive.rounding = Rounding::same(8.0);
    
    // Hovered widgets
    visuals.widgets.hovered.bg_fill = colors.background;
    visuals.widgets.hovered.fg_stroke = Stroke::new(1.5, colors.primary);
    visuals.widgets.hovered.rounding = Rounding::same(8.0);
    
    // Active widgets
    visuals.widgets.active.bg_fill = colors.primary;
    visuals.widgets.active.fg_stroke = Stroke::new(1.0, Color32::WHITE);
    visuals.widgets.active.rounding = Rounding::same(8.0);
    
    // Selection
    visuals.selection = Selection {
        bg_fill: colors.primary.linear_multiply(0.2),
        stroke: Stroke::new(1.0, colors.primary),
    };
    
    // Setup the fonts
    let mut style = Style::default();
    
    // Font definitions from OxiCloud web using system fonts
    style.text_styles = [
        (TextStyle::Heading, FontId::new(24.0, FontFamily::Proportional)),
        (TextStyle::Body, FontId::new(16.0, FontFamily::Proportional)),
        (TextStyle::Monospace, FontId::new(14.0, FontFamily::Monospace)),
        (TextStyle::Button, FontId::new(16.0, FontFamily::Proportional)),
        (TextStyle::Small, FontId::new(12.0, FontFamily::Proportional)),
    ].into();
    
    // Apply the visuals and style
    ctx.set_visuals(visuals);
    ctx.set_style(style);
}

/// Custom widgets styled after OxiCloud
pub mod widgets {
    use egui::{Ui, Vec2, Response, Sense, pos2, Rect, epaint::RectShape, Shape, Stroke, Color32, Rounding, TextEdit};
    
    use super::OxiCloudColors;
    
    /// Create a primary button styled like OxiCloud
    pub fn primary_button(ui: &mut Ui, text: &str) -> Response {
        let colors = OxiCloudColors::default();
        let desired_size = Vec2::new(0.0, 36.0);
        
        ui.style_mut().visuals.widgets.inactive.bg_fill = colors.primary;
        ui.style_mut().visuals.widgets.inactive.fg_stroke = Stroke::new(1.0, Color32::WHITE);
        ui.style_mut().visuals.widgets.inactive.rounding = Rounding::same(8.0);
        
        ui.style_mut().visuals.widgets.hovered.bg_fill = colors.primary.linear_multiply(0.9);
        ui.style_mut().visuals.widgets.hovered.fg_stroke = Stroke::new(1.0, Color32::WHITE);
        
        ui.style_mut().visuals.widgets.active.bg_fill = colors.primary.linear_multiply(0.8);
        ui.style_mut().visuals.widgets.active.fg_stroke = Stroke::new(1.0, Color32::WHITE);
        
        let button = ui.add(egui::Button::new(text).min_size(desired_size));
        
        // Reset styles
        ui.reset_style();
        
        button
    }
    
    /// Create a secondary button styled like OxiCloud
    pub fn secondary_button(ui: &mut Ui, text: &str) -> Response {
        let colors = OxiCloudColors::default();
        let desired_size = Vec2::new(0.0, 36.0);
        
        ui.style_mut().visuals.widgets.inactive.bg_fill = Color32::from_rgb(240, 243, 247); // #f0f3f7
        ui.style_mut().visuals.widgets.inactive.fg_stroke = Stroke::new(1.0, colors.text_primary);
        ui.style_mut().visuals.widgets.inactive.rounding = Rounding::same(8.0);
        
        ui.style_mut().visuals.widgets.hovered.bg_fill = Color32::from_rgb(230, 233, 237);
        ui.style_mut().visuals.widgets.hovered.fg_stroke = Stroke::new(1.0, colors.text_primary);
        
        ui.style_mut().visuals.widgets.active.bg_fill = Color32::from_rgb(220, 223, 227);
        ui.style_mut().visuals.widgets.active.fg_stroke = Stroke::new(1.0, colors.text_primary);
        
        let button = ui.add(egui::Button::new(text).min_size(desired_size));
        
        // Reset styles
        ui.reset_style();
        
        button
    }
    
    /// Create a styled text input with OxiCloud styling
    pub fn styled_text_input(ui: &mut Ui, text: &mut String, hint_text: &str) -> Response {
        let colors = OxiCloudColors::default();
        
        ui.style_mut().visuals.widgets.inactive.bg_fill = Color32::from_rgb(249, 250, 251); // #f9fafb
        ui.style_mut().visuals.widgets.inactive.fg_stroke = Stroke::new(1.0, colors.text_primary);
        ui.style_mut().visuals.widgets.inactive.rounding = Rounding::same(8.0);
        
        ui.style_mut().visuals.widgets.hovered.bg_fill = Color32::WHITE;
        ui.style_mut().visuals.widgets.hovered.fg_stroke = Stroke::new(1.0, colors.primary);
        
        let response = ui.add(TextEdit::singleline(text)
            .hint_text(hint_text)
            .desired_width(f32::INFINITY));
        
        // Reset styles
        ui.reset_style();
        
        response
    }
    
    /// Create a styled file/folder card similar to OxiCloud web
    pub fn file_card(ui: &mut Ui, name: &str, icon: &str, is_folder: bool) -> Response {
        let colors = OxiCloudColors::default();
        let card_size = Vec2::new(180.0, 150.0);
        let (rect, response) = ui.allocate_exact_size(card_size, Sense::click());
        
        if ui.is_rect_visible(rect) {
            let visuals = ui.style().interact(&response);
            
            // Card background
            let mut bg_color = colors.card_background;
            if response.hovered() {
                bg_color = Color32::from_rgb(240, 248, 255); // #f0f8ff light blue on hover
            }
            
            let rect_shape = RectShape::new(
                rect, 
                Rounding::same(8.0), 
                bg_color,
                Stroke::new(1.0, Color32::from_rgb(220, 220, 220))
            );
            
            ui.painter().add(Shape::Rect(rect_shape));
            
            // File/folder icon
            let icon_rect = Rect::from_center_size(
                pos2(rect.center().x, rect.min.y + 55.0),
                Vec2::new(50.0, 50.0)
            );
            
            if is_folder {
                // Folder icon styling
                let folder_color = Color32::from_rgb(255, 234, 167); // #ffeaa7
                let folder_tab_color = Color32::from_rgb(253, 203, 110); // #fdcb6e
                
                // Folder background
                ui.painter().rect_filled(
                    icon_rect,
                    Rounding::same(8.0),
                    folder_color
                );
                
                // Folder tab
                ui.painter().rect_filled(
                    Rect::from_min_size(icon_rect.min, Vec2::new(icon_rect.width(), 15.0)),
                    Rounding::same(8.0),
                    folder_tab_color
                );
            } else {
                // File icon styling
                let file_color = Color32::from_rgb(226, 232, 240); // #e2e8f0
                
                // File background
                ui.painter().rect_filled(
                    icon_rect,
                    Rounding::same(4.0),
                    file_color
                );
                
                // "Lines" on the file
                let line_color = Color32::from_rgb(160, 174, 192); // #a0aec0
                let line_height = 4.0;
                let line_margin = 10.0;
                
                // First line
                ui.painter().rect_filled(
                    Rect::from_min_size(
                        pos2(icon_rect.min.x + line_margin, icon_rect.min.y + 15.0),
                        Vec2::new(icon_rect.width() - (line_margin * 2.0), line_height)
                    ),
                    Rounding::same(0.0),
                    line_color
                );
                
                // Second line
                ui.painter().rect_filled(
                    Rect::from_min_size(
                        pos2(icon_rect.min.x + line_margin, icon_rect.min.y + 25.0),
                        Vec2::new(icon_rect.width() - (line_margin * 2.0) - 10.0, line_height)
                    ),
                    Rounding::same(0.0),
                    line_color
                );
            }
            
            // Text label
            let text_rect = Rect::from_min_size(
                pos2(rect.min.x + 10.0, rect.min.y + 110.0),
                Vec2::new(rect.width() - 20.0, 30.0)
            );
            
            ui.painter().text(
                text_rect.center(),
                egui::Align2::CENTER_CENTER,
                name,
                egui::FontId::new(14.0, egui::FontFamily::Proportional),
                colors.text_primary
            );
        }
        
        response
    }
}

/// Apply the OxiCloud logo to a ui panel
pub fn render_oxicloud_logo(ui: &mut egui::Ui, size: f32) {
    let colors = OxiCloudColors::default();
    
    ui.horizontal(|ui| {
        // Create a circular background for the logo
        let (rect, _) = ui.allocate_exact_size(egui::Vec2::splat(size), egui::Sense::hover());
        
        if ui.is_rect_visible(rect) {
            // Draw the circle
            ui.painter().circle_filled(
                rect.center(),
                size / 2.0,
                colors.primary,
            );
            
            // Draw a cloud shape in white
            let cloud_points = get_cloud_shape(rect.center(), size * 0.6);
            
            ui.painter().add(egui::Shape::convex_polygon(
                cloud_points,
                Color32::WHITE,
                Stroke::NONE,
            ));
        }
        
        // Add text part of logo if not small
        if size >= 30.0 {
            ui.add_space(10.0);
            ui.colored_label(
                colors.text_primary,
                egui::RichText::new("OxiCloud")
                    .size(size * 0.48)
                    .strong(),
            );
        }
    });
}

/// Get the points to draw the cloud shape for the OxiCloud logo
fn get_cloud_shape(center: egui::Pos2, size: f32) -> Vec<egui::Pos2> {
    let half_size = size / 2.0;
    let quarter_size = size / 4.0;
    
    // Simplified cloud shape points adapted from the SVG
    vec![
        // Bottom left
        egui::pos2(center.x - half_size, center.y + quarter_size),
        // Bottom middle left
        egui::pos2(center.x - quarter_size, center.y + quarter_size),
        // Bottom middle
        egui::pos2(center.x, center.y + quarter_size),
        // Bottom middle right
        egui::pos2(center.x + quarter_size, center.y + quarter_size),
        // Bottom right
        egui::pos2(center.x + half_size, center.y + quarter_size),
        // Right edge
        egui::pos2(center.x + half_size, center.y),
        // Right top
        egui::pos2(center.x + half_size, center.y - quarter_size),
        // Top right
        egui::pos2(center.x + quarter_size, center.y - half_size),
        // Top middle
        egui::pos2(center.x, center.y - half_size),
        // Top left
        egui::pos2(center.x - quarter_size, center.y - half_size),
        // Left top
        egui::pos2(center.x - half_size, center.y - quarter_size),
        // Left edge
        egui::pos2(center.x - half_size, center.y),
    ]
}