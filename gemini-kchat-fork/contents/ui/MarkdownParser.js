.pragma library

// Simple Markdown Parser for QML TextEdit
// Handles basic markdown (bold, italic, code) and custom LaTeX-like math blocks

function parse(text) {
    if (!text) return "";

    // 1. Escape HTML special characters mostly (but we will insert our own HTML)
    // Actually, incoming text from API is raw. We should escape < and > unless they are code.
    // However, simplest way is to process markdown tokens and wrap them.

    var output = text;

    // HTML Entity Encoding for safety (basic)
    output = output.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

    // 2. Code Blocks (```code```)
    // Replace ```language ... ``` with a pre styled block
    output = output.replace(/```(\w*)\n([\s\S]*?)```/g, function (match, lang, code) {
        return "<br><pre style='background-color:#31363b; color:#eff0f1; padding:10px; border-radius:4px;'>" +
            code.trim() + "</pre><br>";
    });

    // 3. Inline Code (`code`)
    output = output.replace(/`([^`]+)`/g, "<code style='background-color:#31363b; color:#eff0f1; padding:2px;'>$1</code>");

    // 4. Math Blocks ($$ ... $$) - Custom handling
    // We format this as a distinct block of text, maybe colored differently to imply "math"
    output = output.replace(/\$\$([\s\S]*?)\$\$/g, function (match, math) {
        // We cannot render real LaTeX, but we can make it look like a "Code Block" 
        // with a specific header or style.
        return "<br><div style='background-color:#232629; border-left: 3px solid #3daee9; padding:8px; margin:4px; font-family:Monospace;'>" +
            "<i>Math Formula:</i><br>" + math.trim() + "</div><br>";
    });

    // 5. Inline Math ($ ... $)
    // Harder to distinguish from normal text, but let's try strict $...$ without spaces inside start/end for safety?
    // Often unsafe. Let's skip inline single $ for now or treat as italic code.

    // 6. Bold (**text**)
    output = output.replace(/\*\*([^*]+)\*\*/g, "<b>$1</b>");

    // 7. Italic (*text*)
    output = output.replace(/\*([^*]+)\*/g, "<i>$1</i>");

    // 8. Headings
    output = output.replace(/^### (.*$)/gim, "<h3>$1</h3>");
    output = output.replace(/^## (.*$)/gim, "<h2>$1</h2>");
    output = output.replace(/^# (.*$)/gim, "<h1>$1</h1>");

    // 9. Links [text](url)
    output = output.replace(/\[([^\]]+)\]\(([^)]+)\)/g, "<a href='$2'>$1</a>");

    // 10. Newlines to <br> (only those not inside pre tags ideally, but simple replace works for chat)
    // We already handled code blocks with <pre>, so we should be careful.
    // Simple approach: Replace \n with <br> ONLY if not inside the pre tag we just generated.
    // Since we encoded code blocks as HTML tags, we can just replace remaining \n.
    // But wait, the previous replacements might have valid \n inside <pre>.
    // Using <pre> tags usually preserves whitespace in HTML view.

    // Let's do a global \n replacement carefully. 
    // Actually, simple chat often prefers <p> or <br>.
    output = output.replace(/\n/g, "<br>");

    return output;
}
