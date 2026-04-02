<!DOCTYPE html>

<html lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
        tailwind.config = {
          darkMode: "class",
          theme: {
            extend: {
              colors: {
                "primary": "#f2c287",
                "primary-dark": "#d9a366",
                "terracotta": "#e67e5d",
                "background-light": "#fcf9f5",
                "background-dark": "#1a1612",
              },
              fontFamily: {
                "display": ["Manrope", "Inter", "sans-serif"]
              },
              borderRadius: {"DEFAULT": "0.5rem", "lg": "1rem", "xl": "1.5rem", "full": "9999px"},
            },
          },
        }
    </script>
<title>Minimarket Inventory Dashboard</title>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
</head>
<body class="bg-background-light dark:bg-background-dark font-display text-slate-900 dark:text-slate-100 min-h-screen">
<div class="relative flex h-auto min-h-screen w-full flex-col overflow-x-hidden pb-24">
<!-- Top Header -->
<header class="flex items-center bg-white dark:bg-slate-900/50 p-4 sticky top-0 z-10 border-b border-slate-200 dark:border-slate-800 backdrop-blur-md">
<div class="flex size-10 shrink-0 items-center justify-center rounded-full mr-3">
<span class="material-symbols-outlined">account_circle</span>
</div>
<div class="flex-1">
<p class="text-xs text-slate-500 dark:text-slate-400 font-medium">Welcome back,</p>
<h2 class="text-slate-900 dark:text-slate-100 text-lg font-bold leading-tight">Good Morning, Admin</h2>
</div>
<div class="flex gap-2">
<button class="flex items-center justify-center rounded-lg size-10 bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300">
<span class="material-symbols-outlined">search</span>
</button>
<button class="flex items-center justify-center rounded-lg size-10 bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 relative">
<span class="material-symbols-outlined">notifications</span>
<span class="absolute top-2 right-2 size-2 bg-red-500 rounded-full border-2 border-white dark:border-slate-800"></span>
</button>
</div>
</header>
<!-- Quick Actions Grid -->
<section class="p-4 pt-6">
<h3 class="text-sm font-bold uppercase tracking-wider text-slate-500 mb-4 px-1">Quick Actions</h3>
<div class="grid grid-cols-4 gap-3">
<button class="flex flex-col items-center gap-2 group">
<div class="size-14 rounded-xl bg-primary text-slate-900 flex items-center justify-center shadow-lg shadow-primary/30 group-active:scale-95 transition-transform">
<span class="material-symbols-outlined text-2xl">add_box</span>
</div>
<span class="text-[11px] font-semibold text-slate-600 dark:text-slate-400">Add Item</span>
</button>
<button class="flex flex-col items-center gap-2 group">
<div class="size-14 rounded-xl bg-slate-900 dark:bg-slate-700 text-white flex items-center justify-center shadow-lg shadow-slate-900/10 group-active:scale-95 transition-transform">
<span class="material-symbols-outlined text-2xl">barcode_scanner</span>
</div>
<span class="text-[11px] font-semibold text-slate-600 dark:text-slate-400">Scan</span>
</button>
<button class="flex flex-col items-center gap-2 group">
<div class="size-14 rounded-xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 flex items-center justify-center shadow-sm group-active:scale-95 transition-transform">
<span class="material-symbols-outlined text-2xl">login</span>
</div>
<span class="text-[11px] font-semibold text-slate-600 dark:text-slate-400">Stock In</span>
</button>
<button class="flex flex-col items-center gap-2 group">
<div class="size-14 rounded-xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 flex items-center justify-center shadow-sm group-active:scale-95 transition-transform">
<span class="material-symbols-outlined text-2xl">logout</span>
</div>
<span class="text-[11px] font-semibold text-slate-600 dark:text-slate-400">Stock Out</span>
</button>
</div>
</section>
<!-- Inventory Summary -->
<section class="p-4">
<h3 class="text-sm font-bold uppercase tracking-wider text-slate-500 mb-4 px-1 text-slate-500 dark:text-slate-400">Inventory Summary</h3>
<div class="grid grid-cols-2 lg:grid-cols-3 gap-4">
<div class="flex flex-col p-4 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm">
<div class="size-10 rounded-lg flex items-center justify-center mb-3">
<span class="material-symbols-outlined">inventory_2</span>
</div>
<p class="text-2xl font-bold text-slate-900 dark:text-slate-100">1,240</p>
<p class="text-xs font-medium text-slate-500">Total Products</p>
</div>
<div class="flex flex-col p-4 rounded-xl dark:bg-orange-900/10 border border-orange-100 dark:border-orange-900/30 shadow-sm">
<div class="size-10 rounded-lg bg-orange-500/10 flex items-center justify-center mb-3">
<span class="material-symbols-outlined">warning</span>
</div>
<p class="text-2xl font-bold dark:text-orange-400">42</p>
<p class="text-xs font-medium">Low Stock Items</p>
</div>
<div class="flex flex-col p-4 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm col-span-2 lg:col-span-1">
<div class="size-10 rounded-lg bg-blue-500/10 flex items-center justify-center mb-3">
<span class="material-symbols-outlined text-blue-500">receipt_long</span>
</div>
<div class="flex items-end justify-between">
<div>
<p class="text-2xl font-bold text-slate-900 dark:text-slate-100">156</p>
<p class="text-xs font-medium text-slate-500">Today's Transactions</p>
</div>
<div class="text-xs font-bold flex items-center mb-1">
<span class="material-symbols-outlined text-sm">trending_up</span> 12%
                        </div>
</div>
</div>
</div>
</section>
<!-- Stock Trend Chart (Mockup) -->
<section class="p-4">
<div class="flex items-center justify-between mb-4 px-1">
<h3 class="text-sm font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">Stock Trend</h3>
<select class="text-xs font-bold bg-transparent border-none focus:ring-0 cursor-pointer">
<option>Last 7 Days</option>
<option>Last 30 Days</option>
</select>
</div>
<div class="w-full bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800">
<div class="relative h-40 flex items-end justify-between gap-2">
<!-- Simple CSS Bar Chart Mockup -->
<div class="w-full rounded-t-sm relative group h-[40%]">
<div class="absolute bottom-0 w-full rounded-t-sm h-[80%] group-hover:bg-primary/80 transition-all"></div>
</div>
<div class="w-full rounded-t-sm relative group h-[60%]">
<div class="absolute bottom-0 w-full rounded-t-sm h-[75%] group-hover:bg-primary/80 transition-all"></div>
</div>
<div class="w-full rounded-t-sm relative group h-[80%]">
<div class="absolute bottom-0 w-full rounded-t-sm h-[90%] group-hover:bg-primary/80 transition-all"></div>
</div>
<div class="w-full rounded-t-sm relative group h-[55%]">
<div class="absolute bottom-0 w-full rounded-t-sm h-[60%] group-hover:bg-primary/80 transition-all"></div>
</div>
<div class="w-full rounded-t-sm relative group h-[70%]">
<div class="absolute bottom-0 w-full rounded-t-sm h-[85%] group-hover:bg-primary/80 transition-all"></div>
</div>
<div class="w-full rounded-t-sm relative group h-[90%]">
<div class="absolute bottom-0 w-full rounded-t-sm h-[95%] group-hover:bg-primary/80 transition-all"></div>
</div>
<div class="w-full rounded-t-sm relative group h-[100%]">
<div class="absolute bottom-0 w-full rounded-t-sm h-[100%] group-hover:bg-primary/80 transition-all"></div>
</div>
</div>
<div class="flex justify-between mt-4 text-[10px] font-bold text-slate-400 uppercase tracking-widest px-1">
<span>Mon</span><span>Tue</span><span>Wed</span><span>Thu</span><span>Fri</span><span>Sat</span><span>Sun</span>
</div>
</div>
</section>
<!-- Bottom Navigation Bar -->
<nav class="fixed bottom-0 left-0 right-0 border-t border-slate-200 dark:border-slate-800 bg-white/90 dark:bg-slate-900/90 backdrop-blur-xl px-4 pb-6 pt-3 flex items-center justify-between z-50">
<a class="flex flex-1 flex-col items-center gap-1" href="#">
<span class="material-symbols-outlined filled" style="font-variation-settings: 'FILL' 1">dashboard</span>
<span class="text-[10px] font-bold">Dashboard</span>
</a>
<a class="flex flex-1 flex-col items-center gap-1 text-slate-400 dark:text-slate-500" href="#">
<span class="material-symbols-outlined">inventory_2</span>
<span class="text-[10px] font-bold">Inventory</span>
</a>
<div class="flex-none -mt-10">
<button class="size-14 rounded-full text-white shadow-lg shadow-primary/40 border-4 border-background-light dark:border-background-dark flex items-center justify-center">
<span class="material-symbols-outlined text-3xl">add</span>
</button>
</div>
<a class="flex flex-1 flex-col items-center gap-1 text-slate-400 dark:text-slate-500" href="#">
<span class="material-symbols-outlined">history</span>
<span class="text-[10px] font-bold">Logs</span>
</a>
<a class="flex flex-1 flex-col items-center gap-1 text-slate-400 dark:text-slate-500" href="#">
<span class="material-symbols-outlined">settings</span>
<span class="text-[10px] font-bold">Settings</span>
</a>
</nav>
</div>
</body></html>