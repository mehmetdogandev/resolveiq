const dateTime = new Intl.DateTimeFormat("tr-TR", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" });
const dateOnly = new Intl.DateTimeFormat("tr-TR", { day: "numeric", month: "long", year: "numeric" });

export function formatDateTime(value: string | null | undefined) {
  return value ? dateTime.format(new Date(value)) : "—";
}

export function formatDate(value: string | null | undefined) {
  return value ? dateOnly.format(new Date(value)) : "—";
}

export function timeAgo(value: string | null | undefined) {
  if (!value) return "—";
  const diff = (Date.now() - new Date(value).getTime()) / 1000;
  if (diff < 60) return "az önce";
  if (diff < 3600) return `${Math.floor(diff / 60)} dk önce`;
  if (diff < 86400) return `${Math.floor(diff / 3600)} sa önce`;
  if (diff < 86400 * 30) return `${Math.floor(diff / 86400)} gün önce`;
  return formatDate(value);
}

export function formatUsd(value: number) {
  if (value === 0) return "$0";
  if (value < 0.01) return `$${value.toFixed(6)}`;
  return `$${value.toFixed(4)}`;
}

export function percent(value: number | null | undefined) {
  return value == null ? "—" : `%${Math.round(value * 100)}`;
}

export function formatMinutes(value: number | null | undefined) {
  if (value == null) return "—";
  if (value < 60) return `${Math.round(value)} dk`;
  const hours = value / 60;
  if (hours < 24) return `${hours.toFixed(1)} sa`;
  return `${(hours / 24).toFixed(1)} gün`;
}
