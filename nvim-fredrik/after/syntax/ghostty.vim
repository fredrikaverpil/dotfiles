" Vim syntax file
" Language: Ghostty config file
" Maintainer: Ghostty <https://github.com/ghostty-org/ghostty>
"
" THIS FILE IS AUTO-GENERATED

if exists('b:current_syntax')
  finish
endif

let b:current_syntax = 'ghostty'

let s:cpo_save = &cpo
set cpo&vim

syn keyword ghosttyConfigKeyword
	\ font-family
	\ font-family-bold
	\ font-family-italic
	\ font-family-bold-italic
	\ font-style
	\ font-style-bold
	\ font-style-italic
	\ font-style-bold-italic
	\ font-synthetic-style
	\ font-feature
	\ font-size
	\ font-variation
	\ font-variation-bold
	\ font-variation-italic
	\ font-variation-bold-italic
	\ font-codepoint-map
	\ font-thicken
	\ adjust-cell-width
	\ adjust-cell-height
	\ adjust-font-baseline
	\ adjust-underline-position
	\ adjust-underline-thickness
	\ adjust-strikethrough-position
	\ adjust-strikethrough-thickness
	\ adjust-overline-position
	\ adjust-overline-thickness
	\ adjust-cursor-thickness
	\ adjust-cursor-height
	\ adjust-box-thickness
	\ grapheme-width-method
	\ freetype-load-flags
	\ theme
	\ background
	\ foreground
	\ selection-foreground
	\ selection-background
	\ selection-invert-fg-bg
	\ minimum-contrast
	\ palette
	\ cursor-color
	\ cursor-invert-fg-bg
	\ cursor-opacity
	\ cursor-style
	\ cursor-style-blink
	\ cursor-text
	\ cursor-click-to-move
	\ mouse-hide-while-typing
	\ mouse-shift-capture
	\ mouse-scroll-multiplier
	\ background-opacity
	\ background-blur-radius
	\ unfocused-split-opacity
	\ unfocused-split-fill
	\ command
	\ initial-command
	\ wait-after-command
	\ abnormal-command-exit-runtime
	\ scrollback-limit
	\ link
	\ link-url
	\ fullscreen
	\ title
	\ class
	\ x11-instance-name
	\ working-directory
	\ keybind
	\ window-padding-x
	\ window-padding-y
	\ window-padding-balance
	\ window-padding-color
	\ window-vsync
	\ window-inherit-working-directory
	\ window-inherit-font-size
	\ window-decoration
	\ window-title-font-family
	\ window-theme
	\ window-colorspace
	\ window-height
	\ window-width
	\ window-save-state
	\ window-step-resize
	\ window-new-tab-position
	\ resize-overlay
	\ resize-overlay-position
	\ resize-overlay-duration
	\ focus-follows-mouse
	\ clipboard-read
	\ clipboard-write
	\ clipboard-trim-trailing-spaces
	\ clipboard-paste-protection
	\ clipboard-paste-bracketed-safe
	\ image-storage-limit
	\ copy-on-select
	\ click-repeat-interval
	\ config-file
	\ config-default-files
	\ confirm-close-surface
	\ quit-after-last-window-closed
	\ quit-after-last-window-closed-delay
	\ initial-window
	\ quick-terminal-position
	\ quick-terminal-screen
	\ quick-terminal-animation-duration
	\ quick-terminal-autohide
	\ shell-integration
	\ shell-integration-features
	\ osc-color-report-format
	\ vt-kam-allowed
	\ custom-shader
	\ custom-shader-animation
	\ macos-non-native-fullscreen
	\ macos-titlebar-style
	\ macos-titlebar-proxy-icon
	\ macos-option-as-alt
	\ macos-window-shadow
	\ macos-auto-secure-input
	\ macos-secure-input-indication
	\ macos-icon
	\ macos-icon-frame
	\ macos-icon-ghost-color
	\ macos-icon-screen-color
	\ linux-cgroup
	\ linux-cgroup-memory-limit
	\ linux-cgroup-processes-limit
	\ linux-cgroup-hard-fail
	\ gtk-single-instance
	\ gtk-titlebar
	\ gtk-tabs-location
	\ adw-toolbar-style
	\ gtk-wide-tabs
	\ gtk-adwaita
	\ desktop-notifications
	\ bold-is-bright
	\ term
	\ enquiry-response
	\ auto-update
	\ auto-update-channel

syn match ghosttyConfigComment /^\s*#.*/ contains=@Spell

hi def link ghosttyConfigComment Comment
hi def link ghosttyConfigKeyword Keyword

let &cpo = s:cpo_save
unlet s:cpo_save
