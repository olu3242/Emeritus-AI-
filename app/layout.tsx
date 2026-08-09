import type { Metadata } from "next";
import type { ReactNode } from "react";
import"./globals.css";

export const metadata:Metadata={title:"Emeritus Curriculum Foundation",description:"Governed curriculum operations"};
export default function RootLayout({children}:{children:ReactNode}){return <html lang="en"><body><a className="skip" href="#main-content">Skip to main content</a>{children}</body></html>;}
