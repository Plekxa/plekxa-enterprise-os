import type { SVGProps } from 'react';

export type IconProps = SVGProps<SVGSVGElement> & { size?: number };

function IconBase({ size = 20, children, ...props }: IconProps & { children: React.ReactNode }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      {...props}
    >
      {children}
    </svg>
  );
}

const makeIcon = (path: React.ReactNode) => {
  const Component = (props: IconProps) => <IconBase {...props}>{path}</IconBase>;
  return Component;
};

export const ArrowRight = makeIcon(<><path d="M5 12h14"/><path d="m13 6 6 6-6 6"/></>);
export const ArrowUpRight = makeIcon(<><path d="M7 17 17 7"/><path d="M7 7h10v10"/></>);
export const Archive = makeIcon(<><rect x="3" y="4" width="18" height="5" rx="1"/><path d="M5 9v10h14V9"/><path d="M10 13h4"/></>);
export const Bell = makeIcon(<><path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9"/><path d="M10 21h4"/></>);
export const BriefcaseBusiness = makeIcon(<><rect x="3" y="7" width="18" height="13" rx="2"/><path d="M8 7V5h8v2"/><path d="M3 12h18"/></>);
export const CalendarDays = makeIcon(<><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18"/></>);
export const ChartNoAxesCombined = makeIcon(<><path d="M3 3v18h18"/><path d="m7 16 4-5 4 3 5-7"/></>);
export const Check = makeIcon(<path d="m5 12 4 4L19 6"/>);
export const CheckCircle = makeIcon(<><circle cx="12" cy="12" r="9"/><path d="m8 12 3 3 5-6"/></>);
export const ChevronRight = makeIcon(<path d="m9 18 6-6-6-6"/>);
export const CircleDollarSign = makeIcon(<><circle cx="12" cy="12" r="9"/><path d="M16 8h-6a2 2 0 0 0 0 4h4a2 2 0 0 1 0 4H8"/><path d="M12 6v12"/></>);
export const ClipboardList = makeIcon(<><rect x="5" y="4" width="14" height="17" rx="2"/><path d="M9 4V2h6v2M9 9h6M9 13h6M9 17h4"/></>);
export const Clock = makeIcon(<><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></>);
export const Download = makeIcon(<><path d="M12 3v12"/><path d="m7 10 5 5 5-5"/><path d="M5 21h14"/></>);
export const FileSignature = makeIcon(<><path d="M6 2h9l3 3v17H6z"/><path d="M14 2v4h4"/><path d="m9 16 2-2 2 2 3-3"/></>);
export const FolderKanban = makeIcon(<><path d="M3 6h7l2 2h9v11H3z"/><path d="M8 11v5M12 11v3M16 11v6"/></>);
export const Globe = makeIcon(<><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a15 15 0 0 1 0 18M12 3a15 15 0 0 0 0 18"/></>);
export const Grid = makeIcon(<><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></>);
export const Handshake = makeIcon(<><path d="m8 11 3 3a2 2 0 0 0 3 0l4-4"/><path d="m16 8 2-2 4 4-2 2M8 8 6 6l-4 4 2 2"/><path d="m10 9 2-2a3 3 0 0 1 4 0l2 2"/></>);
export const Kanban = makeIcon(<><rect x="3" y="4" width="5" height="16" rx="1"/><rect x="10" y="4" width="5" height="10" rx="1"/><rect x="17" y="4" width="4" height="13" rx="1"/></>);
export const LayoutDashboard = makeIcon(<><rect x="3" y="3" width="8" height="8" rx="1"/><rect x="13" y="3" width="8" height="5" rx="1"/><rect x="13" y="10" width="8" height="11" rx="1"/><rect x="3" y="13" width="8" height="8" rx="1"/></>);
export const LayoutList = makeIcon(<><path d="M8 6h13M8 12h13M8 18h13"/><circle cx="4" cy="6" r="1"/><circle cx="4" cy="12" r="1"/><circle cx="4" cy="18" r="1"/></>);
export const LibraryBig = makeIcon(<><rect x="4" y="3" width="5" height="18" rx="1"/><rect x="10" y="3" width="5" height="18" rx="1"/><path d="m16 5 4-1 3 16-4 1z"/></>);
export const LifeBuoy = makeIcon(<><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="3"/><path d="m6 6 4 4M14 14l4 4M18 6l-4 4M10 14l-4 4"/></>);
export const Lightbulb = makeIcon(<><path d="M9 18h6M10 22h4"/><path d="M8 14a6 6 0 1 1 8 0c-1 1-1 2-1 4H9c0-2 0-3-1-4"/></>);
export const Megaphone = makeIcon(<><path d="M3 11v4h4l10 4V7L7 11z"/><path d="M7 15l1 5h3"/></>);
export const MoreHorizontal = makeIcon(<><circle cx="5" cy="12" r="1" fill="currentColor"/><circle cx="12" cy="12" r="1" fill="currentColor"/><circle cx="19" cy="12" r="1" fill="currentColor"/></>);
export const Music = makeIcon(<><path d="M9 18V5l10-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="16" cy="16" r="3"/></>);
export const Newspaper = makeIcon(<><path d="M4 5h16v15H4z"/><path d="M8 9h8M8 13h8M8 17h5"/></>);
export const PlaySquare = makeIcon(<><rect x="3" y="3" width="18" height="18" rx="2"/><path d="m10 8 6 4-6 4z"/></>);
export const Plus = makeIcon(<path d="M12 5v14M5 12h14"/>);
export const ScrollText = makeIcon(<><path d="M6 3h12v18H6a3 3 0 0 1 0-6h12"/><path d="M9 7h6M9 11h6"/></>);
export const Search = makeIcon(<><circle cx="11" cy="11" r="7"/><path d="m20 20-4-4"/></>);
export const Settings = makeIcon(<><circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 0 0-.1-1l2-1-2-4-2 1a7 7 0 0 0-2-1l-.3-2h-5l-.3 2a7 7 0 0 0-2 1l-2-1-2 4 2 1a7 7 0 0 0 0 2l-2 1 2 4 2-1a7 7 0 0 0 2 1l.3 2h5l.3-2a7 7 0 0 0 2-1l2 1 2-4-2-1a7 7 0 0 0 .1-1z"/></>);
export const SlidersHorizontal = makeIcon(<><path d="M4 6h16M4 12h16M4 18h16"/><circle cx="9" cy="6" r="2"/><circle cx="15" cy="12" r="2"/><circle cx="8" cy="18" r="2"/></>);
export const Sparkles = makeIcon(<><path d="m12 3 1.5 4.5L18 9l-4.5 1.5L12 15l-1.5-4.5L6 9l4.5-1.5z"/><path d="m19 15 .8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8z"/></>);
export const TrendingUp = makeIcon(<><path d="M3 17 9 11l4 4 8-9"/><path d="M15 6h6v6"/></>);
export const UserRound = makeIcon(<><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></>);
export const Users = makeIcon(<><circle cx="9" cy="8" r="4"/><path d="M2 21a7 7 0 0 1 14 0"/><circle cx="17" cy="9" r="3"/><path d="M16 15a6 6 0 0 1 6 6"/></>);
export const X = makeIcon(<path d="M6 6l12 12M18 6 6 18"/>);
export const Shield = makeIcon(<><path d="M12 3 20 6v6c0 5-3.5 8-8 10-4.5-2-8-5-8-10V6z"/><path d="m9 12 2 2 4-5"/></>);
export const Layers = makeIcon(<><path d="m12 2 9 5-9 5-9-5z"/><path d="m3 12 9 5 9-5"/><path d="m3 17 9 5 9-5"/></>);
export const Percent = makeIcon(<><path d="m19 5-14 14"/><circle cx="7" cy="7" r="2"/><circle cx="17" cy="17" r="2"/></>);
