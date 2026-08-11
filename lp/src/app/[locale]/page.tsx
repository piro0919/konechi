import { getTranslations, setRequestLocale } from "next-intl/server";
import Image from "next/image";
import type { ReactNode } from "react";
import { LanguageSwitch } from "./language-switch";

const REPO = "https://github.com/piro0919/konechi";
const DOWNLOAD = `${REPO}/releases/latest`;

type PageProps = {
  params: Promise<{ locale: string }>;
};

/// 帯と帯の境目に置く波。直線で切るより柔らかくなる
function Wave({ color, flip = false }: { color: string; flip?: boolean }) {
  return (
    <svg
      aria-hidden="true"
      className={`block h-12 w-full ${flip ? "rotate-180" : ""}`}
      preserveAspectRatio="none"
      viewBox="0 0 1440 48"
    >
      <path
        d="M0 24c120 18 240 24 360 18s240-30 360-30 240 24 360 30 240 0 360-18v48H0z"
        fill={color}
      />
    </svg>
  );
}

function DownloadButton({ children }: { children: ReactNode }) {
  return (
    <a
      className="inline-block rounded-full bg-[var(--color-pink)] px-9 py-4 font-bold text-white shadow-[0_10px_0_0_var(--color-pink-deep)] transition active:translate-y-1 active:shadow-[0_4px_0_0_var(--color-pink-deep)]"
      href={DOWNLOAD}
    >
      {children}
    </a>
  );
}

export default async function Page({ params }: PageProps) {
  const { locale } = await params;
  setRequestLocale(locale);

  const t = await getTranslations();

  // "Wi-Fi" はハイフンで折り返されてしまうので、その語だけ切らせない
  const tagline = t("hero.tagline")
    .split("Wi-Fi")
    .flatMap((part, index) =>
      index === 0
        ? [part]
        : [
            <span className="whitespace-nowrap" key={index}>
              Wi-Fi
            </span>,
            part,
          ],
    );

  const states = [
    { accent: "var(--color-blue)", key: "wired", src: "/konechi-wired.png" },
    { accent: "var(--color-sky)", key: "wifi", src: "/konechi-wifi.png" },
    { accent: "#b9a9b6", key: "offline", src: "/konechi-offline.png" },
  ] as const;

  const features = [
    { art: "/lp-switch.png", key: "truth", shot: false },
    { art: "/shot-settings.png", key: "details", shot: true },
    { art: "/lp-vpn.png", key: "vpn", shot: false },
    { art: "/lp-quiet.png", key: "quiet", shot: false },
  ] as const;

  return (
    <>
      {/* 見出し */}
      <section className="dots relative overflow-hidden px-6 pt-20 pb-16">
        <div
          className="blob -top-20 -left-20 h-80 w-80"
          style={{ background: "var(--color-pink-soft)" }}
        />
        <div
          className="blob top-40 -right-24 h-96 w-96"
          style={{ background: "var(--color-sky)" }}
        />
        <div className="relative mx-auto flex max-w-5xl flex-col items-center gap-12 lg:flex-row">
          <div className="flex flex-1 flex-col items-center gap-6 text-center lg:items-start lg:text-left">
            <div className="flex items-center gap-3">
              <span className="rounded-full border-2 border-[var(--color-pink)] bg-white px-4 py-1 font-bold text-[var(--color-pink-deep)] text-sm">
                macOS
              </span>
              <LanguageSwitch />
            </div>
            <h1 className="text-balance text-4xl font-black leading-[1.35] tracking-tight sm:text-[2.75rem]">
              <span className="marker">{tagline}</span>
            </h1>
            <p className="max-w-md text-lg leading-relaxed opacity-80">
              {t("hero.lead")}
            </p>
            <div className="flex flex-col items-center gap-3 lg:items-start">
              <DownloadButton>{t("hero.download")}</DownloadButton>
              <p className="text-sm opacity-60">{t("hero.requirement")}</p>
            </div>
          </div>

          <div className="relative flex flex-1 justify-center">
            <Image
              alt=""
              className="w-full max-w-md rotate-2 rounded-2xl shadow-[0_24px_60px_-12px_rgba(58,20,32,0.45)]"
              height={620}
              priority
              src="/shot-menu.png"
              width={570}
            />
            <Image
              alt=""
              className="-bottom-16 -left-16 absolute w-48 drop-shadow-2xl sm:w-64"
              height={1024}
              priority
              src="/lp-hero.png"
              width={1536}
            />
          </div>
        </div>
      </section>

      <Wave color="#ffffff" />

      {/* 表情 */}
      <section className="bg-white px-6 pb-20">
        <div className="mx-auto flex max-w-5xl flex-col gap-10">
          <div className="flex flex-col gap-3 text-center">
            <h2 className="text-3xl font-black">
              <span className="marker">{t("states.title")}</span>
            </h2>
            <p className="opacity-70">{t("states.lead")}</p>
          </div>
          <ul className="grid gap-6 sm:grid-cols-3">
            {states.map(({ accent, key, src }, index) => (
              <li
                className={`flex flex-col items-center gap-4 rounded-[32px] border-4 border-[var(--color-cream-deep)] bg-[var(--color-cream)] px-4 py-8 shadow-sm transition hover:-translate-y-2 hover:rotate-0 ${
                  index === 0 ? "sm:-rotate-2" : index === 2 ? "sm:rotate-2" : ""
                }`}
                key={key}
              >
                <Image alt="" className="h-auto w-auto" height={110} src={src} width={165} />
                <span
                  className="rounded-full px-4 py-1 font-bold text-sm text-white"
                  style={{ background: accent }}
                >
                  {t(`states.${key}`)}
                </span>
              </li>
            ))}
          </ul>
        </div>
      </section>

      <Wave color="var(--color-cream)" />

      {/* 分かること */}
      <section className="dots relative overflow-hidden px-6 pb-24">
        <div
          className="blob top-1/3 -left-32 h-96 w-96"
          style={{ background: "var(--color-sky)" }}
        />
        <div className="relative mx-auto flex max-w-5xl flex-col gap-16">
          <h2 className="text-center text-3xl font-black">
            <span className="marker">{t("features.title")}</span>
          </h2>
          {features.map(({ art, key, shot }, index) => (
            <div
              className={`flex flex-col items-center gap-8 rounded-[32px] border-4 border-white bg-white/70 p-8 sm:gap-14 sm:p-10 ${
                index % 2 === 0 ? "sm:flex-row" : "sm:flex-row-reverse"
              }`}
              key={key}
            >
              <div className="flex flex-1 justify-center">
                <Image
                  alt=""
                  className={
                    shot
                      ? "w-full max-w-[200px] rounded-xl shadow-xl"
                      : "w-full max-w-[240px] drop-shadow-lg"
                  }
                  height={shot ? 986 : 1024}
                  src={art}
                  width={shot ? 530 : 1536}
                />
              </div>
              <div className="flex flex-[1.3] flex-col gap-3 text-center sm:text-left">
                <h3 className="font-bold text-xl">
                  {t(`features.${key}.title`)}
                </h3>
                <p className="leading-relaxed opacity-80">
                  {t(`features.${key}.body`)}
                </p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 入れ方 */}
      <section className="relative overflow-hidden bg-[var(--color-pink)] px-6 py-20 text-white">
        <div
          className="blob -top-24 right-10 h-72 w-72"
          style={{ background: "#ffffff", opacity: 0.35 }}
        />
        <div className="relative mx-auto flex max-w-3xl flex-col items-center gap-6 text-center">
          <Image
            alt=""
            className="w-full max-w-lg rounded-3xl shadow-xl"
            height={630}
            src="/lp-og.png"
            width={1200}
          />
          <h2 className="font-black text-3xl">{t("install.title")}</h2>
          <p className="max-w-xl leading-relaxed">{t("install.body")}</p>
          <a
            className="inline-block rounded-full bg-white px-9 py-4 font-bold text-[var(--color-pink-deep)] shadow-[0_10px_0_0_rgba(0,0,0,0.15)] transition active:translate-y-1 active:shadow-[0_4px_0_0_rgba(0,0,0,0.15)]"
            href={DOWNLOAD}
          >
            {t("install.cta")}
          </a>
        </div>
      </section>

      <footer className="flex justify-center gap-6 bg-[var(--color-cream)] px-6 py-10 text-sm">
        <a className="font-semibold opacity-60 hover:opacity-100" href={REPO}>
          {t("footer.source")}
        </a>
        <a
          className="font-semibold opacity-60 hover:opacity-100"
          href={`${REPO}/releases`}
        >
          {t("footer.releases")}
        </a>
      </footer>
    </>
  );
}
