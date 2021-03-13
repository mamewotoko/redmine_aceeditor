module RedmineAceEditorPlugin
  module Patches
    module RedmineAceEditorPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          # alias_method_chain :wikitoolbar_for, :aceeditor,
          alias_method :wikitoolbar_for_without_aceeditor, :wikitoolbar_for
          alias_method :wikitoolbar_for, :wikitoolbar_for_with_aceeditor
        end
      end

      module InstanceMethods
        def wikitoolbar_for_with_aceeditor(field_id, preview_url = preview_text_path)
          keybind = User.current.aceeditor_preference[:keybind]
          if keybind == "textarea"
            # TODO: really?
            return
          end
          
          heads_for_aceeditor

          url = "#{Redmine::Utils.relative_url_root}/help/#{current_language.to_s.downcase}/wiki_syntax.html"
          # result = javascript_tag("var wikiToolbar = new jsToolBar(document.getElementById('#{field_id}')); wikiToolbar.setHelpLink('#{escape_javascript url}'); wikiToolbar.setPreviewUrl('#{escape_javascript preview_url}'); wikiToolbar.draw();")
          result = ""

          if keybind.nil? or keybind == ""
            keybind = "emacs"
          end

          theme = User.current.aceeditor_preference[:theme]
          if theme.nil? or theme == ""
            theme= "twilight"
          end

          wikitoolbar_for_without_aceeditor(field_id) +
          javascript_tag(%(
            (function(){
              var textarea = $('##{field_id}');
              var div = $('<div></div>');
              div.css({width: '100%', height: '400px'});
              div.attr('id', '#{field_id}_ace');
              textarea.after(div);
              textarea.hide();
              var editor = ace.edit("#{field_id}_ace", {mode: "ace/mode/markdown"});
              editor.getSession().setValue(textarea.val());
              editor.renderer.setShowGutter(true);
              editor.getSession().on('change', function(){
                textarea.val(editor.getSession().getValue());
              });
              editor.setTheme("ace/theme/#{theme}");
              editor.setKeyboardHandler("ace/keyboard/#{keybind}");
              editor.session.setMode("ace/mode/markdown");
              editor.session.setTabSize(4);
              editor.session.setUseSoftTabs(true);
              editor.setOption("showInvisibles", true);

              var base = textarea.parent().parent();
              //hide toolbar buttons
              base.find("div.jstElements").hide();
              base.find("a.tab-preview").on("click", function(event){
                  div.hide();
              });
              base.find ("a.tab-edit").on("click", function(event){
                  div.show();
              });
            })();
          ))
        end

        def heads_for_aceeditor
          unless @heads_for_aceeditor_included
            content_for :header_tags do
              javascript_include_tag("ace", :plugin => :redmine_zzz_aceeditor) +
                javascript_include_tag("textarea-as-ace-editor.min", :plugin => :redmine_zzz_aceeditor) +
                javascript_include_tag("mode-markdown", :plugin => :redmine_zzz_aceeditor) +
                javascript_include_tag("ext-static_highlight", :plugin => :redmine_zzz_aceeditor)
              # + javascript_include_tag("jstoolbar/lang/jstoolbar-#{current_language.to_s.downcase}")
              # + stylesheet_link_tag('jstoolbar')
            end
            @heads_for_aceeditor_included = true
          end
        end
      end
    end
  end
end


unless Redmine::WikiFormatting::Markdown::Helper.included_modules.include?(RedmineAceEditorPlugin::Patches::RedmineAceEditorPatch)
   Redmine::WikiFormatting::Markdown::Helper.send(:include, RedmineAceEditorPlugin::Patches::RedmineAceEditorPatch)
end

# TODO: control plugin load order more specific way (e.g. list plugins in config.pluguins)
if  Redmine::Plugin.installed? :redmine_pandoc_formatter
  unless RedminePandocFormatter::Helper.included_modules.include?(RedmineAceEditorPlugin::Patches::RedmineAceEditorPatch)
    RedminePandocFormatter::Helper.send(:include, RedmineAceEditorPlugin::Patches::RedmineAceEditorPatch)
  end
end
