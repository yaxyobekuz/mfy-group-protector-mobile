"use client";

/**
 * TIL — TANLOV VA MATN OLISH.
 *
 * ⚠️ STANDART TIL — O'ZBEKCHA (LOTIN). Telegram sozlamasidan
 * taxmin qilinmaydi: sabab `locales.ts` da.
 *
 * ⚠️ TIL `localStorage` DA, SERVERDA EMAS (`locales.ts` izohi).
 *
 * ⚠️ BIRINCHI RENDER HAR DOIM STANDART TIL BILAN: saqlangan til
 * `useEffect` ichida o'qiladi. Sabab — bu sahifalar STATIK
 * chiqariladi (`output: export`) va server HTML'i `localStorage`
 * ni bila olmaydi. Birinchi renderda darhol o'qilsa, server va
 * mijoz HTML'i mos kelmay, React HIDRATATSIYA XATOSI berardi va
 * ekran bo'sh qolardi.
 *
 */

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";

import {
  translate,
  type MessageKey,
} from "@/shared/config/dictionary";
import {
  DEFAULT_LOCALE,
  LOCALE_DEFS,
  isLocale,
  type Locale,
} from "@/shared/config/locales";

const STORAGE_KEY = "vsh.locale";

/** Matn olish funksiyasi — komponentlarda shu ishlatiladi. */
export type Translate = (
  key: MessageKey,
  params?: Record<string, string | number>,
) => string;

interface LocaleValue {
  locale: Locale;
  setLocale: (next: Locale) => void;
  t: Translate;
}

const LocaleContext = createContext<LocaleValue | null>(null);

const readStored = (): Locale | null => {
  if (typeof window === "undefined") return null;

  try {
    const value = window.localStorage.getItem(STORAGE_KEY);
    return isLocale(value) ? value : null;
  } catch {
    // ⚠️ JIM: Telegram ichida `localStorage` ba'zi holatlarda
    // taqiqlangan (maxfiy rejim) va bu butun ilovani yiqitmasligi
    // kerak — til shunchaki standart holatda qoladi.
    return null;
  }
};

export const LocaleProvider = ({ children }: { children: ReactNode }) => {
  const [locale, setLocaleState] = useState<Locale>(DEFAULT_LOCALE);

  /**
   * ⚠️ SAQLANGAN TANLOV BO'LMASA — STANDART TIL (`uz`) QOLADI.
   * Telegram tilidan taxmin QILINMAYDI (`locales.ts` izohi).
   */
  useEffect(() => {
    const stored = readStored();
    if (stored) setLocaleState(stored);
  }, []);

  /**
   * ⚠️ `<html lang>` HAM YANGILANADI: ekran o'quvchi (screen
   * reader) va brauzerning so'z ko'chirish qoidalari shu
   * belgidan o'qiydi. Yangilanmasa, ruscha matn o'zbekcha
   * qoidalar bilan o'qilardi.
   */
  useEffect(() => {
    document.documentElement.lang = LOCALE_DEFS[locale].htmlLang;
  }, [locale]);

  const setLocale = useCallback((next: Locale) => {
    setLocaleState(next);

    try {
      window.localStorage.setItem(STORAGE_KEY, next);
    } catch {
      // Saqlab bo'lmasa — til shu seans uchun amal qiladi.
    }
  }, []);

  const value = useMemo<LocaleValue>(
    () => ({
      locale,
      setLocale,
      t: (key, params) => translate(locale, key, params),
    }),
    [locale, setLocale],
  );

  return <LocaleContext.Provider value={value}>{children}</LocaleContext.Provider>;
};

/**
 * ⚠️ XATO OTADI, zahira qiymat QAYTARMAYDI (`useSession` bilan
 * ayni qoida): provider unutilgan bo'lsa, ilova standart tilda
 * jimgina ishlab ketardi va buni hech kim sezmasdi.
 */
export const useLocale = (): LocaleValue => {
  const value = useContext(LocaleContext);
  if (!value) {
    throw new Error("useLocale faqat <LocaleProvider> ichida ishlatiladi");
  }
  return value;
};

/** Qisqa yo'l — faqat matn kerak bo'lganda. */
export const useT = (): Translate => useLocale().t;
