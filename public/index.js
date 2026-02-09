const ALLOWED_SITES = [
    "https://c0delistener.firebaseapp.com/",
    "localhost"
];

// check referrer
const ref = document.referrer || "";
if (!ALLOWED_SITES.some(site => ref.startsWith(site))) {
    document.body.innerHTML = "403 Forbidden";
    throw new Error("Unauthorized site");
}

"use strict";

const form = document.getElementById("sj-form");
const addressInput = document.getElementById("sj-address");
const searchEngine = document.getElementById("sj-search-engine");
const tabsStrip = document.getElementById("tabs-strip");
const addTabBtn = document.getElementById("add-tab-btn");
const webviewContainer = document.getElementById("webview-container");
const homeTemplate = document.getElementById("home-template");
const bookmarkBtn = document.getElementById("nav-bookmark");
const bookmarkBar = document.getElementById("bookmark-bar");

let tabs = [];
let activeTabId = null;
let tabCounter = 0;
let bookmarks = JSON.parse(localStorage.getItem("delta_bookmarks") || "[]");

// Init Proxy
const { ScramjetController } = $scramjetLoadController();
const scramjet = new ScramjetController({
    files: { wasm: "/scram/scramjet.wasm.wasm", all: "/scram/scramjet.all.js", sync: "/scram/scramjet.sync.js" },
});
scramjet.init();
const connection = new BareMux.BareMuxConnection("/baremux/worker.js");

// --- Bookmark Functions ---
function renderBookmarks() {
    bookmarkBar.innerHTML = "";
    bookmarks.forEach(bm => {
        const div = document.createElement("div");
        div.className = "bookmark-item";
        const iconUrl = `https://www.google.com/s2/favicons?domain=${bm.url}&sz=32`;
        div.innerHTML = `<img src="${iconUrl}" class="bookmark-icon"><span>${bm.title}</span>`;
        div.onclick = () => navigateToUrl(bm.url);
        // Right click to delete
        div.oncontextmenu = (e) => {
            e.preventDefault();
            if(confirm("Delete this bookmark?")) removeBookmark(bm.url);
        };
        bookmarkBar.appendChild(div);
    });
}

function updateBookmarkIcon() {
    const currentTab = tabs.find(t => t.id === activeTabId);
    if (!currentTab || !currentTab.currentUrl) {
        bookmarkBtn.classList.remove("active");
        bookmarkBtn.querySelector('i').className = "fa-regular fa-star";
        return;
    }
    const isBookmarked = bookmarks.some(b => b.url === currentTab.currentUrl);
    if (isBookmarked) {
        bookmarkBtn.classList.add("active");
        bookmarkBtn.querySelector('i').className = "fa-solid fa-star";
    } else {
        bookmarkBtn.classList.remove("active");
        bookmarkBtn.querySelector('i').className = "fa-regular fa-star";
    }
}

function toggleBookmark() {
    const currentTab = tabs.find(t => t.id === activeTabId);
    if (!currentTab || !currentTab.currentUrl) return;

    const url = currentTab.currentUrl;
    const index = bookmarks.findIndex(b => b.url === url);

    if (index !== -1) {
        bookmarks.splice(index, 1);
    } else {
        let title = url.replace(/^https?:\/\/(www\.)?/, '').split('/')[0];
        bookmarks.push({ url, title: title.substring(0, 15) });
    }
    localStorage.setItem("delta_bookmarks", JSON.stringify(bookmarks));
    renderBookmarks();
    updateBookmarkIcon();
}

function removeBookmark(url) {
    bookmarks = bookmarks.filter(b => b.url !== url);
    localStorage.setItem("delta_bookmarks", JSON.stringify(bookmarks));
    renderBookmarks();
    updateBookmarkIcon();
}

// --- Tab Functions ---
function createTab(url = null) {
    tabCounter++;
    const tabId = tabCounter;
    const tabEl = document.createElement("div");
    tabEl.className = "tab";
    tabEl.dataset.id = tabId;
    tabEl.innerHTML = `<span class="tab-title">New Tab</span><button class="tab-close"><i class="fa-solid fa-xmark"></i></button>`;
    tabEl.onclick = (e) => { if(!e.target.closest('.tab-close')) switchTab(tabId); };
    tabEl.querySelector('.tab-close').onclick = (e) => { e.stopPropagation(); closeTab(tabId); };
    tabsStrip.insertBefore(tabEl, addTabBtn);

    const contentEl = homeTemplate.cloneNode(true);
    contentEl.id = `content-${tabId}`;
    contentEl.style.display = "none";
    webviewContainer.appendChild(contentEl);

    tabs.push({ id: tabId, el: tabEl, contentEl: contentEl, iframe: null, currentUrl: url });
    switchTab(tabId);
    if(url) navigateToUrl(url);
}

function closeTab(id) {
    const index = tabs.findIndex(t => t.id === id);
    if (index === -1) return;
    const tab = tabs[index];
    tab.el.remove();
    tab.contentEl.remove();
    if(tab.iframe && tab.iframe.frame) tab.iframe.frame.remove();
    tabs.splice(index, 1);
    if (activeTabId === id && tabs.length > 0) switchTab(tabs[Math.max(0, index - 1)].id);
    else if (tabs.length === 0) createTab();
}

function switchTab(id) {
    activeTabId = id;
    const currentTab = tabs.find(t => t.id === id);
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    currentTab.el.classList.add('active');
    tabs.forEach(t => {
        t.contentEl.style.display = "none";
        if (t.iframe) t.iframe.frame.style.display = "none";
    });
    if (currentTab.iframe) currentTab.iframe.frame.style.display = "block";
    else currentTab.contentEl.style.display = "flex";
    addressInput.value = currentTab.currentUrl || "";
    updateBookmarkIcon();
}

async function navigateToUrl(inputUrl) {
    const currentTab = tabs.find(t => t.id === activeTabId);
    if (!currentTab) return;
    try { await registerSW(); } catch (err) { throw err; }
    const url = search(inputUrl, searchEngine.value);

    let wispUrl = (location.protocol === "https:" ? "wss" : "ws") + "://" + location.host + "/wisp/";
    if ((await connection.getTransport()) !== "/libcurl/index.mjs") {
        await connection.setTransport("/libcurl/index.mjs", [{ websocket: wispUrl }]);
    }

    if (!currentTab.iframe) {
        const frame = scramjet.createFrame();
        frame.frame.classList.add('sj-frame');
        currentTab.contentEl.style.display = "none";
        webviewContainer.appendChild(frame.frame);
        currentTab.iframe = frame;
        currentTab.el.querySelector('.tab-title').textContent = inputUrl;
    } else {
        currentTab.iframe.frame.style.display = 'block';
    }
    currentTab.currentUrl = inputUrl;
    currentTab.iframe.go(url);
    updateBookmarkIcon();
}

// Listeners
form.onsubmit = (e) => { e.preventDefault(); navigateToUrl(addressInput.value); };
addTabBtn.onclick = () => createTab();
bookmarkBtn.onclick = () => toggleBookmark();
document.getElementById("nav-reload").onclick = () => {
    const t = tabs.find(x => x.id === activeTabId);
    if(t && t.iframe) try { t.iframe.frame.contentWindow.location.reload(); } catch(e){}
};
document.getElementById("nav-back").onclick = () => {
    const t = tabs.find(x => x.id === activeTabId);
    if(t && t.iframe) try { t.iframe.frame.contentWindow.history.back(); } catch(e){}
};
document.getElementById("nav-forward").onclick = () => {
    const t = tabs.find(x => x.id === activeTabId);
    if(t && t.iframe) try { t.iframe.frame.contentWindow.history.forward(); } catch(e){}
};

// Start
renderBookmarks();
createTab();
