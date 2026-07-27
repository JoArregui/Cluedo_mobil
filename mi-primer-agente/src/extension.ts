import * as vscode from 'vscode';

export function activate(context: vscode.ExtensionContext) {
    const handler: vscode.ChatRequestHandler = async (request, context, stream, token) => {
        
        // 1. Verificar si hay un editor de texto abierto
        const editor = vscode.window.activeTextEditor;

        if (request.prompt === 'analiza') {
            if (editor) {
                const document = editor.document;
                const text = document.getText();
                
                stream.markdown(`He leído el archivo: **${document.fileName}**\n\n`);
                stream.markdown(`El archivo tiene ${document.lineCount} líneas de código.`);
                
                // Aquí podrías enviar el texto a una API de LLM (como OpenAI o Claude)
                // O realizar un análisis simple directamente.
            } else {
                stream.markdown('No hay ningún archivo abierto para analizar.');
            }
            return;
        }

        stream.markdown('Puedes decirme `@mi-agente analiza` para ver el estado del archivo actual.');
    };

    const agent = vscode.chat.createChatParticipant('mi-agente.asistente', handler);
    context.subscriptions.push(agent);
}

export function deactivate() {}