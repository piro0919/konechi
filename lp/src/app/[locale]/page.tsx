import { getTranslations, setRequestLocale } from "next-intl/server";
import Image from "next/image";

const REPO = "https://github.com/piro0919/konechi";
const DOWNLOAD = `${REPO}/releases/latest`;

type PageProps = {
  params: Promise<{ locale: string }>;
};

export default async function Page({ params }: PageProps) {
  const { locale } = await params;
  setRequestLocale(locale);

  const t = await getTranslations();

  const states = [
    { key: "wired", src: "/konechi-wired.png" },
    { key: "wifi", src: "/konechi-wifi.png" },
    { key: "offline", src: "/konechi-offline.png" },
  ] as const;

  const features = ["truth", "details", "vpn", "quiet"] as const;

  return (
    <main className="mx-auto flex max-w-3xl flex-col gap-24 px-6 py-20">
      <section className="flex flex-col items-center gap-6 text-center">
        <Image
          alt="Konechi"
          className="rounded-[22%] shadow-lg"
          height={140}
          priority
          src="/icon.png"
          width={140}
        />
        <h1 className="text-4xl font-bold tracking-tight sm:text-5xl">
          {t("hero.tagline")}
        </h1>
        <p className="max-w-xl text-lg leading-relaxed opacity-80">
          {t("hero.lead")}
        </p>
        <div className="flex flex-col items-center gap-3">
          <a
            className="rounded-full bg-[var(--color-pink)] px-8 py-3 font-semibold text-white transition hover:bg-[var(--color-pink-deep)]"
            href={DOWNLOAD}
          >
            {t("hero.download")}
          </a>
          <p className="text-sm opacity-60">{t("hero.requirement")}</p>
        </div>
      </section>

      <section className="flex flex-col gap-8">
        <div className="flex flex-col gap-2 text-center">
          <h2 className="text-2xl font-bold">{t("states.title")}</h2>
          <p className="opacity-75">{t("states.lead")}</p>
        </div>
        <ul className="grid grid-cols-3 gap-4">
          {states.map(({ key, src }) => (
            <li
              className="flex flex-col items-center gap-3 rounded-2xl bg-white/60 px-3 py-6"
              key={key}
            >
              <Image alt="" height={72} src={src} width={108} />
              <span className="font-semibold">{t(`states.${key}`)}</span>
            </li>
          ))}
        </ul>
      </section>

      <section className="flex flex-col gap-8">
        <h2 className="text-center text-2xl font-bold">
          {t("features.title")}
        </h2>
        <ul className="grid gap-5 sm:grid-cols-2">
          {features.map((key) => (
            <li className="rounded-2xl bg-white/60 p-6" key={key}>
              <h3 className="mb-2 font-bold">{t(`features.${key}.title`)}</h3>
              <p className="text-sm leading-relaxed opacity-80">
                {t(`features.${key}.body`)}
              </p>
            </li>
          ))}
        </ul>
      </section>

      <section className="flex flex-col items-center gap-5 rounded-3xl bg-white/60 px-8 py-12 text-center">
        <h2 className="text-2xl font-bold">{t("install.title")}</h2>
        <p className="max-w-xl text-sm leading-relaxed opacity-80">
          {t("install.body")}
        </p>
        <a
          className="rounded-full bg-[var(--color-pink)] px-8 py-3 font-semibold text-white transition hover:bg-[var(--color-pink-deep)]"
          href={DOWNLOAD}
        >
          {t("install.cta")}
        </a>
      </section>

      <footer className="flex justify-center gap-6 pb-6 text-sm opacity-60">
        <a href={REPO}>{t("footer.source")}</a>
        <a href={`${REPO}/releases`}>{t("footer.releases")}</a>
      </footer>
    </main>
  );
}
