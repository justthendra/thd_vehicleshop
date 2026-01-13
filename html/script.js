let selectedVehicle = null;
let L = {}; // Language

window.addEventListener("message", function(e) {
    const d = e.data;
    if (!d || !d.action) return;

    // --- Performans Güncelle ---
    if (d.action === "updateStats") {
        updateVehicleStats(d);
    }

    // --- Menü Aç ---
    if (d.action === "openShop") {
        L = d.locale || {};
        
        document.getElementById("shop-container").classList.remove("hidden");

        loadCategories(d.categories);  // { key, label }
        loadVehicles(d.vehicles);

        applyTranslations();
    }

    // --- Menü Kapat ---
    if (d.action === "closeShop") {
        document.getElementById("shop-container").classList.add("hidden");
    }

    // --- Araç Listesi Güncelle ---
    if (d.action === "updateVehicles") {
        loadVehicles(d.vehicles);
    }
});


// ======================================================
//  PERFORMANCE STATS
// ======================================================
function updateVehicleStats(stats) {
    document.getElementById("stat-speed").style.width = (stats.speed || 0) + "%";
    document.getElementById("stat-accel").style.width = (stats.accel || 0) + "%";
    document.getElementById("stat-brakes").style.width = (stats.braking || 0) + "%";
    document.getElementById("stat-handling").style.width = (stats.handling || 0) + "%";
}


// ======================================================
//  KATEGORİLERİ YÜKLE
// ======================================================
function loadCategories(cats) {
    const box = document.getElementById("category-list");
    box.innerHTML = "";

    // --- Tümü Butonu ---
    const all = document.createElement("div");
    all.className = "category-item";
    all.innerText = L.all || "All";
    all.onclick = () => selectCategory("all");
    box.appendChild(all);

    // --- Kategoriler ---
    cats.forEach(cat => {
        const div = document.createElement("div");
        div.className = "category-item";
        div.innerText = cat.label;         // ✔ ÇEVRİLMİŞ İSİM
        div.onclick = () => selectCategory(cat.key); // ✔ ORJİNAL KATEGORİ
        box.appendChild(div);
    });
}


// ======================================================
//  KATEGORİ SEÇİMİ
// ======================================================
function selectCategory(cat) {
    fetch(`https://thd_vehicleshop/selectCategory`, {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({ category: cat })
    });
}


// ======================================================
//  ARAÇ LİSTESİ
// ======================================================
function loadVehicles(list) {
    const box = document.getElementById("vehicle-list");
    box.innerHTML = "";

    list.forEach(v => {
        const div = document.createElement("div");
        div.className = "vehicle-item";

        // Foto
        const img = document.createElement("img");
        img.className = "vehicle-img";
        img.src = `https://docs.fivem.net/vehicles/${v.model}.webp`;
        img.onerror = () => img.src = "default.png";
        div.appendChild(img);

        // Araç Adı
        const lbl = document.createElement("div");
        lbl.innerHTML = `<strong>${v.label}</strong>`;
        div.appendChild(lbl);

        div.onclick = () => selectVehicle(v);

        box.appendChild(div);
    });
}


// ======================================================
//  ARAÇ SEÇİMİ
// ======================================================
function selectVehicle(v) {
    selectedVehicle = v;

    // ÇEVRİLMİŞ KATEGORİ İSMİ
    const catKey = v.category;
    const translated = L.categories?.[catKey] || v.category;

    document.getElementById("vehicle_name").innerText = v.label;
    document.getElementById("vehicle-price").innerText = "$" + v.price.toLocaleString();
    document.getElementById("vehicle-category").innerText = translated;

    fetch(`https://thd_vehicleshop/selectVehicle`, {
        method: "POST",
        headers: {"Content-Type":"application/json"},
        body: JSON.stringify(v)
    });
}


// ======================================================
//  BUTONLAR
// ======================================================
document.getElementById("test-btn").onclick = () => {
    fetch(`https://thd_vehicleshop/testDrive`, {
        method: "POST",
        headers: {"Content-Type":"application/json"},
        body: JSON.stringify(selectedVehicle)
    });
};

document.getElementById("buy-btn").onclick = () => {
    if (!selectedVehicle) return;

    fetch(`https://thd_vehicleshop/buyVehicle`, {
        method: "POST",
        headers: {"Content-Type":"application/json"},
        body: JSON.stringify({
            model: selectedVehicle.model,
            price: selectedVehicle.price
        })
    });
};


document.getElementById("cancel-btn").onclick = () => {
    fetch(`https://thd_vehicleshop/closeShop`, {
        method: "POST"
    });
};


// ======================================================
//  SCROLL EVENTLERİ
// ======================================================
document.getElementById("category-list").addEventListener("wheel", (e) => {
    e.preventDefault();
    document.getElementById("category-list").scrollLeft += e.deltaY;
}, { passive: false });

document.getElementById("vehicle-list").addEventListener("wheel", (e) => {
    e.preventDefault();
    document.getElementById("vehicle-list").scrollLeft += e.deltaY;
}, { passive: false });


// ======================================================
//  DİL ÇEVİRİSİ UYGULA
// ======================================================
function applyTranslations() {
    document.getElementById("buy-btn").innerText = L.buy;
    document.getElementById("test-btn").innerText = L.test_drive;
    document.getElementById("cancel-btn").innerText = L.cancel;

    document.getElementById("stat-label-speed").innerText = L.speed;
    document.getElementById("stat-label-accel").innerText = L.acceleration;
    document.getElementById("stat-label-braking").innerText = L.braking;
    document.getElementById("stat-label-handling").innerText = L.handling;
    document.getElementById("stat-label-performance").innerText = L.performance;

    document.getElementById("vehicle_name").innerText = L.vehicle_name;
}