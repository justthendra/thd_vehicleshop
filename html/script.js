let selectedVehicle = null;

window.addEventListener("message", function(e) {
    const d = e.data;
    if (!d || !d.action) return;

    if (d.action === "updateStats") {
        updateVehicleStats(d);
    }

    if (d.action === "openShop") {
        document.getElementById("shop-container").classList.remove("hidden");
        loadCategories(d.categories);
        loadVehicles(d.vehicles);
    }

    if (d.action === "closeShop") {
        document.getElementById("shop-container").classList.add("hidden");
    }

    if (d.action === "updateVehicles") {
        loadVehicles(d.vehicles);
    }
});

function updateVehicleStats(stats) {
    document.getElementById("stat-speed").style.width = stats.speed + "%";
    document.getElementById("stat-accel").style.width = stats.accel + "%";
    document.getElementById("stat-handling").style.width = stats.handling + "%";
    document.getElementById("stat-brakes").style.width = stats.brakes + "%";
}

/* KATEGORİLER */
function loadCategories(cats) {
    const box = document.getElementById("category-list");
    box.innerHTML = "";

    const all = document.createElement("div");
    all.className = "category-item";
    all.innerText = "Tümü";
    all.onclick = () => selectCategory("all");
    box.appendChild(all);

    cats.forEach(cat => {
        const div = document.createElement("div");
        div.className = "category-item";
        div.innerText = cat.toUpperCase();
        div.onclick = () => selectCategory(cat);
        box.appendChild(div);
    });
}

function selectCategory(cat) {
    fetch(`https://thd_vehicleshop/selectCategory`, {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({ category: cat })
    });
}

/* ARAÇ LİSTESİ */
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

        const lbl = document.createElement("div");
        lbl.innerHTML = `<strong>${v.label}</strong>`;
        div.appendChild(lbl);

        div.onclick = () => selectVehicle(v);

        box.appendChild(div);
    });
}

/* ARAÇ SEÇİMİ */
function selectVehicle(v) {
    selectedVehicle = v;

    document.getElementById("vehicle-name").innerText = v.label;
    document.getElementById("vehicle-price").innerText = "$" + v.price.toLocaleString();
    document.getElementById("vehicle-category").innerText = v.category;

    fetch(`https://thd_vehicleshop/selectVehicle`, {
        method: "POST",
        headers: {"Content-Type":"application/json"},
        body: JSON.stringify(v)
    });
}

document.getElementById("test-btn").onclick = () => {
    fetch(`https://thd_vehicleshop/testDrive`, {
        method: "POST",
        headers: {"Content-Type":"application/json"},
        body: JSON.stringify(selectedVehicle)
    });
};


document.getElementById("buy-btn").onclick = () => {
    fetch(`https://thd_vehicleshop/buyVehicle`, {
        method: "POST",
        headers: {"Content-Type":"application/json"},
        body: JSON.stringify(selectedVehicle)
    });
};

document.getElementById("cancel-btn").onclick = () => {
    fetch(`https://thd_vehicleshop/closeShop`, {
        method: "POST"
    });
};

document.getElementById("category-list").addEventListener("wheel", (e) => {
    e.preventDefault();
    document.getElementById("category-list").scrollLeft += e.deltaY;
}, { passive: false });

document.getElementById("vehicle-list").addEventListener("wheel", (e) => {
    e.preventDefault();
    document.getElementById("vehicle-list").scrollLeft += e.deltaY;
}, { passive: false });
