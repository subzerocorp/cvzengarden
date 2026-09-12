(** The HTML document a sandboxed preview frame runs. The chrome mutates the [<style>] elements and
    the article in place, so Theme swaps cross-fade instead of reloading. *)

let style_id_base = "rz-base"
let style_id_theme = "rz-theme"
let style_id_paper = "rz-paper"

(** A stylesheet is inert text inside [<style>] except for its own closing tag, which is neutralised
    here. *)
let inert_css css =
  Js.String.replaceByRe
    ~regexp:(Js.Re.fromStringWithFlags "</style" ~flags:"gi")
    ~replacement:"<\\/style" css

let view_attr (view : View_mode.t) = View_mode.to_key view

let frame ~base_css ~paper_css ~theme_css ~(view : View_mode.t) ~article =
  String.concat ""
    [
      "<!DOCTYPE html><html lang=\"en\" data-view=\"";
      view_attr view;
      "\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width, \
       initial-scale=1\">";
      "<style id=\"";
      style_id_base;
      "\">";
      inert_css base_css;
      "</style>";
      "<style id=\"";
      style_id_theme;
      "\">";
      inert_css theme_css;
      "</style>";
      "<style id=\"";
      style_id_paper;
      "\">";
      inert_css paper_css;
      "</style>";
      "</head><body>";
      article;
      "</body></html>";
    ]

(** A downloadable document: the Skeleton with one Theme inlined. *)
let standalone ~theme_css resume = Skeleton.render ~style:(inert_css theme_css) resume
