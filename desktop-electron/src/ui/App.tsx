import { useMemo, useState } from "react";
import {
  AppWindow, BookOpen, Boxes, ChevronDown, CircleHelp, Download,
  FileText, FolderCheck, Grid2X2, Home, Mail, Moon, Search, Settings2,
  ShieldCheck, Sparkles, Sun, Wrench
} from "lucide-react";

type Section = "home" | "catalog" | "installed" | "tools" | "contact" | "help";
type AppItem = { name: string; category: string; description: string; icon: string; compatibility: string };

const sampleApps: AppItem[] = [
  { name: "LibreOffice", category: "Oficina", description: "Suite ofimática completa para documentos, hojas de cálculo y presentaciones.", icon: "L", compatibility: "Ubuntu 20.04+" },
  { name: "GIMP", category: "Diseño", description: "Edición y retoque de imágenes con herramientas profesionales.", icon: "G", compatibility: "Ubuntu 20.04+" },
  { name: "Audacity", category: "Audio", description: "Grabación y edición multipista de audio.", icon: "A", compatibility: "Ubuntu 20.04+" },
  { name: "VLC", category: "Multimedia", description: "Reproductor multimedia para prácticamente cualquier formato.", icon: "V", compatibility: "Ubuntu 20.04+" },
  { name: "Inkscape", category: "Diseño", description: "Diseño e ilustración vectorial.", icon: "I", compatibility: "Ubuntu 20.04+" },
  { name: "KeePassXC", category: "Seguridad", description: "Gestor local de contraseñas con base de datos cifrada.", icon: "K", compatibility: "Ubuntu 20.04+" }
];

const nav: { id: Section; label: string; icon: typeof Home; group: string }[] = [
  { id: "home", label: "Inicio", icon: Home, group: "Espacio de trabajo" },
  { id: "catalog", label: "Catálogo AppImage", icon: Grid2X2, group: "Espacio de trabajo" },
  { id: "installed", label: "Mis aplicaciones", icon: FolderCheck, group: "Espacio de trabajo" },
  { id: "tools", label: "Herramientas Punto Vuela", icon: Wrench, group: "Espacio de trabajo" },
  { id: "contact", label: "Contacto y propuestas", icon: Mail, group: "Sistema" },
  { id: "help", label: "Ayuda y documentación", icon: CircleHelp, group: "Sistema" }
];

export default function App() {
  const [section, setSection] = useState<Section>("home");
  const [query, setQuery] = useState("");
  const [category, setCategory] = useState("Todas");
  const [dark, setDark] = useState(true);
  const categories = ["Todas", ...Array.from(new Set(sampleApps.map((item) => item.category)))];
  const filtered = useMemo(() => sampleApps.filter((item) =>
    (category === "Todas" || item.category === category) &&
    (item.name + " " + item.description + " " + item.category).toLocaleLowerCase("es").includes(query.toLocaleLowerCase("es"))
  ), [category, query]);
  const active = nav.find((item) => item.id === section)!;

  return <div className={dark ? "app-shell dark" : "app-shell light"}>
    <aside className="sidebar">
      <div className="brand">
        <div className="brand-mark" aria-hidden="true">V</div>
        <div><strong>PUNTOS VUELA</strong><span>TOOLKIT</span></div>
      </div>
      {["Espacio de trabajo", "Sistema"].map((group) => <div className="nav-group" key={group}>
        <p className="nav-heading">{group}</p>
        {nav.filter((item) => item.group === group).map((item) => {
          const Icon = item.icon;
          return <button key={item.id} className={section === item.id ? "nav-item active" : "nav-item"}
            onClick={() => setSection(item.id)} aria-current={section === item.id ? "page" : undefined}>
            <Icon size="1.125rem" aria-hidden="true" /><span>{item.label}</span>
          </button>;
        })}
      </div>)}
      <div className="sidebar-footer"><ShieldCheck size="1rem" /> Aplicación de escritorio</div>
    </aside>

    <main className="main-content">
      <header className="topbar">
        <div className="breadcrumb"><span>Toolkit</span><ChevronDown size="0.9rem" /><strong>{active.label}</strong></div>
        <div className="top-actions">
          <label className="global-search"><Search size="1rem" /><span className="sr-only">Buscar en la aplicación</span>
            <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Buscar aplicaciones, herramientas..." />
            <kbd>⌘ K</kbd>
          </label>
          <button className="icon-button" onClick={() => setDark(!dark)} aria-label={dark ? "Cambiar a tema claro" : "Cambiar a tema oscuro"}>{dark ? <Sun /> : <Moon />}</button>
        </div>
      </header>

      <section className="page">
        {section === "home" && <>
          <div className="hero">
            <div><span className="eyebrow"><Sparkles size="0.9rem" /> TU ESPACIO DIGITAL</span>
              <h1>Todo Linux.<br /><em>En un solo lugar.</em></h1>
              <p>Descubre aplicaciones, gestiona tus herramientas y mantén tu entorno de trabajo al día.</p>
              <button className="primary-button" onClick={() => setSection("catalog")}>Explorar catálogo <Grid2X2 size="1rem" /></button>
            </div>
            <div className="hero-art" aria-hidden="true"><div className="orbit orbit-one"></div><div className="orbit orbit-two"></div><div className="hero-logo">V</div><span className="floating-chip chip-a"><Boxes size="1rem" /> Aplicaciones</span><span className="floating-chip chip-b"><Wrench size="1rem" /> Herramientas</span></div>
          </div>
          <div className="section-heading"><div><span className="eyebrow">EMPIEZA POR AQUÍ</span><h2>Tu espacio de trabajo</h2></div><span className="muted">Edición preview · 0.2.0</span></div>
          <div className="quick-grid">
            <button className="quick-card" onClick={() => setSection("catalog")}><span className="quick-icon"><Grid2X2 /></span><strong>Catálogo AppImage</strong><span>Explora aplicaciones compatibles</span><Download size="1rem" /></button>
            <button className="quick-card" onClick={() => setSection("installed")}><span className="quick-icon"><FolderCheck /></span><strong>Mis aplicaciones</strong><span>Administra tus descargas</span><AppWindow size="1rem" /></button>
            <button className="quick-card" onClick={() => setSection("tools")}><span className="quick-icon"><Wrench /></span><strong>Herramientas Punto Vuela</strong><span>Utilidades y recursos digitales</span><Settings2 size="1rem" /></button>
          </div>
        </>}

        {section === "catalog" && <><div className="page-title"><div><span className="eyebrow">DESCUBRE SOFTWARE</span><h1>Catálogo de aplicaciones</h1><p>Encuentra herramientas para tu día a día en Linux.</p></div><span className="result-pill">{filtered.length} resultados</span></div>
          <div className="filter-panel"><div className="filter-label"><span>Filtrar por categoría</span><span className="muted">{filtered.length} aplicaciones</span></div>
            <div className="category-list" aria-label="Categorías de aplicaciones">{categories.map((item) => <button key={item} className={category === item ? "category-chip selected" : "category-chip"} onClick={() => setCategory(item)} aria-pressed={category === item}>{item}</button>)}</div>
          </div>
          <div className="app-grid">{filtered.map((item) => <article className="app-card" key={item.name}>
            <div className="app-card-top"><div className="app-icon">{item.icon}</div><span className="compatibility">{item.compatibility}</span></div>
            <span className="category-tag">{item.category}</span><h3>{item.name}</h3><p>{item.description}</p>
            <button className="secondary-button" onClick={() => window.alert("La instalación se habilitará al conectar el gestor local de AppImages.")}>Ver aplicación <Download size="0.95rem" /></button>
          </article>)}</div>
        </>}

        {section === "installed" && <EmptyState icon={<FolderCheck />} title="Tus aplicaciones, bajo control" description="Aquí aparecerán las AppImages que descargues, con su estado, tamaño, actualizaciones e integración en el escritorio." />}
        {section === "tools" && <EmptyState icon={<Wrench />} title="Herramientas Punto Vuela" description="Accede a las utilidades y recursos digitales del ecosistema Punto Vuela. El catálogo se conectará con los repositorios oficiales." />}
        {section === "contact" && <EmptyState icon={<Mail />} title="Contacto y propuestas" description="Formulario accesible para proponer nuevas aplicaciones. La conexión con el servicio de correo se migrará y verificará antes de publicar." />}
        {section === "help" && <EmptyState icon={<BookOpen />} title="Ayuda y documentación" description="Guías de instalación, gestión de aplicaciones y resolución de problemas." />}
      </section>
      <footer className="app-footer"><span>Puntos Vuela Toolkit <b>·</b> Nueva edición</span><span>Diseñada para Linux · Sin permisos de administrador</span></footer>
    </main>
  </div>;
}

function EmptyState({ icon, title, description }: { icon: React.ReactNode; title: string; description: string }) {
  return <div className="empty-state"><div className="empty-icon">{icon}</div><span className="eyebrow">EN DESARROLLO</span><h1>{title}</h1><p>{description}</p></div>;
}