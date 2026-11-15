// Pequenas melhorias de experiência para a página de demonstração.
document.addEventListener("DOMContentLoaded", () => {
  const year = document.querySelector("#year");
  if (year) year.textContent = new Date().getFullYear();

  // Respeita a preferência do visitante por movimento reduzido.
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (!reduceMotion) document.documentElement.style.scrollBehavior = "smooth";
});
