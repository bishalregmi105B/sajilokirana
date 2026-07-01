'use client';

export function CategoryChips({ categories, selected, onSelect }: {
  categories: string[];
  selected: string | null;
  onSelect: (cat: string | null) => void;
}) {
  return (
    <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
      <button
        onClick={() => onSelect(null)}
        className={`shrink-0 px-4 py-1.5 rounded-pill text-sm font-medium transition ${
          selected === null ? 'bg-primary text-white' : 'bg-surface-tint text-charcoal hover:bg-primary/10'
        }`}
      >
        All
      </button>
      {categories.map(cat => (
        <button
          key={cat}
          onClick={() => onSelect(cat)}
          className={`shrink-0 px-4 py-1.5 rounded-pill text-sm font-medium transition ${
            selected === cat ? 'bg-primary text-white' : 'bg-surface-tint text-charcoal hover:bg-primary/10'
          }`}
        >
          {cat}
        </button>
      ))}
    </div>
  );
}
