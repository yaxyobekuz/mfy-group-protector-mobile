/**
 * TELEGRAM MINI APP SDK — YUPQA QOBIQ.
 *
 * ⚠️ `window.Telegram` GA TO'G'RIDAN-TO'G'RI MUROJAAT QILINMAYDI (bu
 * fayldan boshqa joyda). Sabab: ilova BRAUZERDA ham ochiladi
 * (ishlab chiqish, sinov) va u yerda `window.Telegram` YO'Q. Har
 * chaqiruv joyida `?.` yozish kerak bo'lardi va amalda bittasi
 * tushib qolib, butun ekran oq bo'lib qolardi.
 *
 * ⚠️ HAR FUNKSIYA BRAUZERDA HAM ISHLAYDI (jim o'tadi yoki zahira
 * qiymat qaytaradi). "Telegramsiz ishlamaydi" degan holat ilovani
 * sinab ko'rishni imkonsiz qilardi.
 *
 * ⚠️ RASMIY `@telegram-apps/sdk` PAKETI ISHLATILMADI: bizga kerak
 * bo'lgani — `initData`, haptic va tema; qolgani (to'lov, qurilma
 * sensorlari) ishlatilmaydi va paket versiyasi Telegram mijozidan
 * oldinda ketganda ilova jim ishlamay qolardi.
 */

/** Faqat bizga kerak bo'lgan qism. */
interface TelegramWebApp {
  initData: string;
  initDataUnsafe?: { user?: { id: number; first_name: string } };
  colorScheme?: "light" | "dark";
  themeParams?: Record<string, string>;
  viewportStableHeight?: number;
  platform?: string;
  version?: string;
  ready: () => void;
  expand: () => void;
  close: () => void;
  openLink?: (url: string) => void;
  setHeaderColor?: (color: string) => void;
  setBackgroundColor?: (color: string) => void;
  disableVerticalSwipes?: () => void;
  onEvent?: (event: string, handler: () => void) => void;
  offEvent?: (event: string, handler: () => void) => void;
  BackButton?: {
    show: () => void;
    hide: () => void;
    onClick: (handler: () => void) => void;
    offClick: (handler: () => void) => void;
  };
  HapticFeedback?: {
    impactOccurred: (style: "light" | "medium" | "heavy") => void;
    notificationOccurred: (type: "error" | "success" | "warning") => void;
    selectionChanged: () => void;
  };
}

declare global {
  interface Window {
    Telegram?: { WebApp?: TelegramWebApp };
  }
}

const webApp = (): TelegramWebApp | null => {
  if (typeof window === "undefined") return null;
  return window.Telegram?.WebApp ?? null;
};

/** Telegram ichidamizmi. */
export const isInsideTelegram = (): boolean => {
  const app = webApp();
  // ⚠️ `initData` BO'SH BO'LSA — TELEGRAM EMAS: obyektning o'zi
  // brauzerda skript yuklangani uchun ham mavjud bo'lishi mumkin,
  // lekin imzolangan satrni faqat Telegram beradi.
  return Boolean(app?.initData);
};

export const getInitData = (): string => webApp()?.initData ?? "";

/**
 * ILOVANI TAYYOR DEB BELGILAYDI.
 *
 * ⚠️ `ready()` CHAQIRILMASA Telegram yuklash ko'rsatkichini
 * OLIB TASHLAMAYDI va fuqaro tayyor ekran ustida aylanayotgan
 * doirani ko'rib turardi.
 */
export const initTelegram = (): void => {
  const app = webApp();
  if (!app) return;

  app.ready();
  app.expand();

  /**
   * ⚠️ VERTIKAL SURISH O'CHIRILADI: Telegram'da pastga tortish
   * oynani yopadi. Murojaat to'ldirayotgan fuqaro ro'yxatni
   * aylantirmoqchi bo'lib, ilovani yopib yuborardi va yozganlari
   * yo'qolardi.
   *
   * ⚠️ `?.` MAJBURIY: usul Telegram'ning eski mijozlarida YO'Q
   * (6.0+ da paydo bo'lgan) va uni shartsiz chaqirish butun
   * ishga tushishni yiqitardi.
   */
  app.disableVerticalSwipes?.();
};

/** Tema — Telegram'dan keladi, ilova unga moslashadi. */
export const getColorScheme = (): "light" | "dark" =>
  webApp()?.colorScheme ?? "light";

export const onThemeChange = (handler: () => void): (() => void) => {
  const app = webApp();
  if (!app?.onEvent) return () => undefined;

  app.onEvent("themeChanged", handler);
  return () => app.offEvent?.("themeChanged", handler);
};

/**
 * SARLAVHA VA FON RANGI.
 *
 * ⚠️ TELEGRAM O'ZINING SARLAVHA PANELINI CHIZADI va u standart
 * holda ilova fonidan boshqa rangda bo'ladi — natijada ekran
 * tepasida begona chiziq ko'rinardi.
 */
export const applyChrome = (background: string): void => {
  const app = webApp();
  app?.setHeaderColor?.(background);
  app?.setBackgroundColor?.(background);
};

/**
 * ORQAGA TUGMASI.
 *
 * ⚠️ TELEGRAM'NING O'Z TUGMASI ISHLATILADI, ekranga ikkinchisini
 * chizish o'rniga: fuqaro Telegram ichidagi barcha ilovalarda shu
 * tugmani bosishga o'rgangan va ikkita orqaga tugmasi qaysi biri
 * nima qilishini noaniq qilardi.
 */
export const showBackButton = (handler: () => void): (() => void) => {
  const app = webApp();
  const button = app?.BackButton;
  if (!button) return () => undefined;

  button.onClick(handler);
  button.show();

  return () => {
    button.offClick(handler);
    button.hide();
  };
};

/**
 * HAPTIK JAVOB.
 *
 * ⚠️ BU BEZAK EMAS: mini-ilovada bosish va natija orasida tarmoq
 * kutish bor va qurilmaning sezilarli javobisiz foydalanuvchi
 * tugmani ikki marta bosadi — natijada ikkita bir xil murojaat
 * yuborilardi.
 */
export const haptic = {
  tap: (): void => webApp()?.HapticFeedback?.impactOccurred("light"),
  press: (): void => webApp()?.HapticFeedback?.impactOccurred("medium"),
  select: (): void => webApp()?.HapticFeedback?.selectionChanged(),
  success: (): void => webApp()?.HapticFeedback?.notificationOccurred("success"),
  error: (): void => webApp()?.HapticFeedback?.notificationOccurred("error"),
};

/**
 * ⚠️ TASHQI HAVOLA TELEGRAM ORQALI OCHILADI: `window.open`
 * mini-ilova ichida ba'zi mijozlarda umuman ishlamaydi va havola
 * jimgina "bosilmaydigan" bo'lib qolardi.
 */
export const openExternal = (url: string): void => {
  const app = webApp();
  if (app?.openLink) {
    app.openLink(url);
    return;
  }
  window.open(url, "_blank", "noopener,noreferrer");
};

export const closeApp = (): void => webApp()?.close();
