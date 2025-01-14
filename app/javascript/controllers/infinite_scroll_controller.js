import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container", "loading"];
  static values = { url: String };

  connect() {
    this.page = 1;
    this.hasNextPage = true; // Indica se há mais páginas
    this.loading = false;
    window.addEventListener("scroll", this.loadMore.bind(this));
  }

  disconnect() {
    window.removeEventListener("scroll", this.loadMore.bind(this));
  }

  loadMore() {
    if (this.loading || !this.hasNextPage) return; // Não faz nada se já estiver carregando ou se não houver mais páginas

    const endOfPage = window.innerHeight + window.scrollY >= document.body.offsetHeight;
    if (endOfPage) {
      this.loadNextPage();
    }
  }

  loadNextPage() {
    this.page += 1;
    this.loading = true;
    this.loadingTarget.style.display = "block";

    fetch(`${this.urlValue}?page=${this.page}`, {
      headers: { Accept: "text/vnd.turbo-stream.html" },
    })
      .then((response) => {
        if (response.status === 204) {
          this.hasNextPage = false; // Sem mais páginas
          throw new Error("Sem mais registros para carregar.");
        }
        if (!response.ok) throw new Error("Erro ao carregar dados.");
        return response.text();
      })
      .then((html) => {
        Turbo.renderStreamMessage(html);
      })
      .catch((error) => console.error("Erro:", error))
      .finally(() => {
        this.loading = false;
        this.loadingTarget.style.display = "none";
      });
  }
}
