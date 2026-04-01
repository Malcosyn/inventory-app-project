<!DOCTYPE html>

<html class="light" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Add New Item - Amber Harvest</title>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&amp;family=Manrope:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<script id="tailwind-config">
    tailwind.config = {
      darkMode: "class",
      theme: {
        extend: {
          colors: {
            "on-tertiary": "#ffffff",
            "on-error-container": "#93000a",
            "surface": "#fcf9f5",
            "on-surface": "#1a1612",
            "error-container": "#ffdad6",
            "on-secondary-fixed-variant": "#57452c",
            "inverse-surface": "#31302c",
            "error": "#ba1a1a",
            "inverse-primary": "#ffbb5e",
            "tertiary-fixed-dim": "#bbcea1",
            "on-background": "#1a1612",
            "inverse-on-surface": "#f5f0eb",
            "tertiary-fixed": "#d7eabb",
            "on-tertiary-container": "#121f04",
            "on-secondary-container": "#281905",
            "tertiary": "#546440",
            "on-primary-fixed": "#2b1700",
            "on-primary": "#ffffff",
            "on-error": "#ffffff",
            "surface-container-high": "#f1eee9",
            "surface-container": "#f7f3ef",
            "primary-fixed": "#ffdcbe",
            "on-secondary": "#ffffff",
            "surface-bright": "#fffcf9",
            "outline": "#85735e",
            "tertiary-container": "#d7eabb",
            "secondary-container": "#fce0bd",
            "primary-fixed-dim": "#ffb96a",
            "outline-variant": "#d5c2ab",
            "surface-container-low": "#fcf9f5",
            "secondary": "#705d42",
            "secondary-fixed": "#fce0bd",
            "on-tertiary-fixed": "#121f04",
            "surface-dim": "#e5e2de",
            "on-tertiary-fixed-variant": "#3d4c2a",
            "on-surface-variant": "#4d4639",
            "surface-container-lowest": "#ffffff",
            "primary-container": "#f2c287",
            "surface-variant": "#f1eee9",
            "on-secondary-fixed": "#281905",
            "on-primary-container": "#422c00",
            "surface-container-highest": "#ebe8e4",
            "background": "#fcf9f5",
            "on-primary-fixed-variant": "#714a00",
            "secondary-fixed-dim": "#dec4a2",
            "primary": "#d9a05b",
            "surface-tint": "#d9a05b"
          },
          fontFamily: {
            "headline": ["Plus Jakarta Sans"],
            "body": ["Manrope"],
            "label": ["Manrope"]
          },
          borderRadius: {"DEFAULT": "0.25rem", "lg": "0.5rem", "xl": "0.75rem", "2xl": "1rem", "full": "9999px"},
        },
      },
    }
  </script>
<style>
    .material-symbols-outlined {
      font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
    }
    body {
      background-color: #fcf9f5;
      font-family: 'Manrope', sans-serif;
    }
    .headline-font {
      font-family: 'Plus Jakarta Sans', sans-serif;
    }
    input::placeholder, select::placeholder {
      color: #85735e;
      opacity: 0.6;
    }
  </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="text-on-surface">
<!-- TopAppBar -->
<header class="fixed top-0 w-full z-50 bg-[#fcf9f5]/80 backdrop-blur-md shadow-sm flex items-center justify-between px-6 py-4 w-full">
<div class="flex items-center gap-3">
<button class="text-on-surface-variant hover:bg-primary-container/10 p-2 rounded-full transition-colors active:scale-95">
<span class="material-symbols-outlined">arrow_back</span>
</button>
<h1 class="font-headline font-bold text-xl text-on-surface tracking-tight">Add New Item</h1>
</div>
<div class="text-primary">
<span class="material-symbols-outlined" data-icon="inventory_2">inventory_2</span>
</div>
</header>
<main class="pt-24 pb-32 px-6 max-w-2xl mx-auto">
<!-- Image Upload Area -->
<section class="mb-8">
<div class="relative group">
<div class="w-full aspect-[4/3] rounded-2xl bg-surface-container-high flex flex-col items-center justify-center border-2 border-dashed border-outline-variant hover:border-primary transition-colors overflow-hidden">
<img alt="Product Placeholder" class="absolute inset-0 w-full h-full object-cover opacity-20 grayscale" data-alt="Close-up of empty wooden grocery shelves in a warm sunlit store with soft bokeh background" src="https://lh3.googleusercontent.com/aida-public/AB6AXuAW5w0c75JanLGInMl5CFO_CIEBvQT1vBs8wo8IfAQ7vrEFBEsVmcZLtFZZXt4DVXiMG3ZU0dxPO_EBcRPJLRV9cbFSVl3q2D8V3ivtySbAl2POjGtfeW9jVW1rvtXfSNCWLd3esSdfgPuoxRykCFlEqWps4k7adJIgJx-eNJnU7qjI9bDeAHu8bfZzm5qAnegZoKuC-7iSPh-djJj8GMooqcF0R42K_Uy7HMahV_-oO__ljx1ttipdWamZRiP92bfE54Wiizzkj3Y"/>
<div class="z-10 flex flex-col items-center gap-2">
<div class="w-14 h-14 rounded-full bg-surface-container-lowest flex items-center justify-center text-primary shadow-sm">
<span class="material-symbols-outlined text-3xl">add_a_photo</span>
</div>
<p class="font-headline font-bold text-on-surface-variant">Upload Product Photo</p>
<p class="text-xs text-on-surface-variant/60 font-medium">PNG, JPG up to 10MB</p>
</div>
</div>
</div>
</section>
<!-- Form Sections -->
<form class="space-y-6">
<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
<!-- Product Name -->
<div class="md:col-span-2">
<label class="block text-xs font-bold uppercase tracking-widest text-on-surface-variant mb-2 ml-1">Product Name</label>
<input class="w-full bg-surface-container-lowest border-none focus:ring-2 focus:ring-primary/20 rounded-xl px-4 py-3.5 text-on-surface font-medium shadow-sm transition-all" placeholder="e.g. Organic Honey Jar" type="text"/>
</div>
<!-- Category -->
<div>
<label class="block text-xs font-bold uppercase tracking-widest text-on-surface-variant mb-2 ml-1">Category</label>
<div class="relative">
<select class="w-full appearance-none bg-surface-container-lowest border-none focus:ring-2 focus:ring-primary/20 rounded-xl px-4 py-3.5 text-on-surface font-medium shadow-sm cursor-pointer">
<option disabled="" selected="">Select category</option>
<option>Pantry</option>
<option>Dairy &amp; Eggs</option>
<option>Fresh Produce</option>
<option>Beverages</option>
<option>Bakery</option>
</select>
<span class="material-symbols-outlined absolute right-4 top-1/2 -translate-y-1/2 text-on-surface-variant pointer-events-none">expand_more</span>
</div>
</div>
<!-- Unit Price -->
<div>
<label class="block text-xs font-bold uppercase tracking-widest text-on-surface-variant mb-2 ml-1">Unit Price</label>
<div class="relative">
<span class="absolute left-4 top-1/2 -translate-y-1/2 text-primary font-bold">$</span>
<input class="w-full bg-surface-container-lowest border-none focus:ring-2 focus:ring-primary/20 rounded-xl pl-8 pr-4 py-3.5 text-on-surface font-medium shadow-sm transition-all" placeholder="0.00" step="0.01" type="number"/>
</div>
</div>
<!-- Initial Stock -->
<div>
<label class="block text-xs font-bold uppercase tracking-widest text-on-surface-variant mb-2 ml-1">Initial Stock</label>
<div class="relative">
<input class="w-full bg-surface-container-lowest border-none focus:ring-2 focus:ring-primary/20 rounded-xl px-4 py-3.5 text-on-surface font-medium shadow-sm transition-all" placeholder="0" type="number"/>
<span class="absolute right-4 top-1/2 -translate-y-1/2 text-on-surface-variant/60 text-sm font-medium">units</span>
</div>
</div>
<!-- Alert Level -->
<div>
<label class="block text-xs font-bold uppercase tracking-widest text-on-surface-variant mb-2 ml-1">Minimum Alert Level</label>
<div class="relative">
<input class="w-full bg-surface-container-lowest border-none focus:ring-2 focus:ring-primary/20 rounded-xl px-4 py-3.5 text-on-surface font-medium shadow-sm transition-all" placeholder="5" type="number"/>
<span class="material-symbols-outlined absolute right-4 top-1/2 -translate-y-1/2 text-error/60 text-xl">notification_important</span>
</div>
</div>
<!-- Supplier -->
<div class="md:col-span-2">
<label class="block text-xs font-bold uppercase tracking-widest text-on-surface-variant mb-2 ml-1">Supplier</label>
<div class="relative">
<select class="w-full appearance-none bg-surface-container-lowest border-none focus:ring-2 focus:ring-primary/20 rounded-xl px-4 py-3.5 text-on-surface font-medium shadow-sm cursor-pointer">
<option disabled="" selected="">Select supplier</option>
<option>Green Valley Farms</option>
<option>Artisan Bakehouse Co.</option>
<option>Morning Mist Dairy</option>
<option>Global Grains Ltd.</option>
</select>
<span class="material-symbols-outlined absolute right-4 top-1/2 -translate-y-1/2 text-on-surface-variant pointer-events-none">store</span>
</div>
</div>
</div>
<!-- Action Buttons -->
<div class="pt-8 space-y-3">
<button class="w-full bg-primary text-on-primary font-headline font-bold py-4 rounded-xl shadow-[0_8px_20px_rgba(217,160,91,0.3)] active:scale-[0.98] transition-all flex items-center justify-center gap-2" type="submit">
<span class="material-symbols-outlined">check_circle</span>
          Save Item
        </button>
<button class="w-full bg-transparent text-on-surface-variant font-headline font-bold py-4 rounded-xl border-2 border-outline-variant/30 hover:bg-surface-container-high transition-colors active:scale-[0.98]" type="button">
          Cancel
        </button>
</div>
</form>
</main>
<!-- BottomNavBar -->
<nav class="fixed bottom-0 left-0 w-full h-20 bg-white/90 backdrop-blur-md flex justify-around items-center px-4 pb-safe shadow-[0_-4px_10px_rgba(0,0,0,0.05)] rounded-t-2xl z-50">
<a class="flex flex-col items-center justify-center text-[#4d4639] opacity-60 hover:opacity-100 transition-opacity active:scale-90 duration-200" href="#">
<span class="material-symbols-outlined" data-icon="dashboard">dashboard</span>
<span class="font-headline text-[10px] font-bold uppercase tracking-wider">Dashboard</span>
</a>
<a class="flex flex-col items-center justify-center text-[#d9a05b] scale-110 transition-all active:scale-90 duration-200" href="#">
<span class="material-symbols-outlined" data-icon="inventory_2" style="font-variation-settings: 'FILL' 1;">inventory_2</span>
<span class="font-headline text-[10px] font-bold uppercase tracking-wider">Products</span>
</a>
<a class="flex flex-col items-center justify-center text-[#4d4639] opacity-60 hover:opacity-100 transition-opacity active:scale-90 duration-200" href="#">
<span class="material-symbols-outlined" data-icon="package_2">package_2</span>
<span class="font-headline text-[10px] font-bold uppercase tracking-wider">Stock</span>
</a>
<a class="flex flex-col items-center justify-center text-[#4d4639] opacity-60 hover:opacity-100 transition-opacity active:scale-90 duration-200" href="#">
<span class="material-symbols-outlined" data-icon="person">person</span>
<span class="font-headline text-[10px] font-bold uppercase tracking-wider">Profile</span>
</a>
</nav>
</body></html>