function closeAllWindows() {
    const clients = workspace.clientList().slice();

    for (let i = 0; i < clients.length; i++) {
        const c = clients[i];

        if (!c.closeable || c.skipTaskbar) {
            continue;
        }

        workspace.activeClient = c;
        workspace.slotWindowClose();
    }
}

registerShortcut(
    "CloseAllWindows",
    "Close All Windows",
    "",
    closeAllWindows
);
