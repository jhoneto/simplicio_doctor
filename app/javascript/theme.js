(function() {
  "use strict";

  // Toggle the side navigation
  document.querySelectorAll("#sidebarToggle, #sidebarToggleTop").forEach(function(toggle) {
    toggle.addEventListener('click', function() {
      document.body.classList.toggle("sidebar-toggled");
      const sidebar = document.querySelector(".sidebar");
      sidebar.classList.toggle("toggled");
      if (sidebar.classList.contains("toggled")) {
        sidebar.querySelectorAll('.collapse').forEach(function(collapse) {
          new bootstrap.Collapse(collapse, { toggle: false }).hide();
        });
      }
    });
  });

  // Close any open menu accordions when window is resized below 768px
  window.addEventListener('resize', function() {
    if (window.innerWidth < 768) {
      document.querySelectorAll('.sidebar .collapse').forEach(function(collapse) {
        new bootstrap.Collapse(collapse, { toggle: false }).hide();
      });
    }

    // Toggle the side navigation when window is resized below 480px
    const sidebar = document.querySelector(".sidebar");
    if (window.innerWidth < 480 && !sidebar.classList.contains("toggled")) {
      document.body.classList.add("sidebar-toggled");
      sidebar.classList.add("toggled");
      sidebar.querySelectorAll('.collapse').forEach(function(collapse) {
        new bootstrap.Collapse(collapse, { toggle: false }).hide();
      });
    }
  });

  // Prevent the content wrapper from scrolling when the fixed side navigation hovered over
  if (document.body.classList.contains("fixed-nav")) {
    document.querySelector(".sidebar").addEventListener('wheel', function(e) {
      if (window.innerWidth > 768) {
        e.preventDefault();
        this.scrollTop += (e.deltaY > 0 ? 30 : -30);
      }
    });
  }

  // Scroll to top button appear
  document.addEventListener('scroll', function() {
    const scrollDistance = window.scrollY;
    const scrollToTop = document.querySelector('.scroll-to-top');
    if (scrollToTop) {
      if (scrollDistance > 100) {
        scrollToTop.style.display = "block";
      } else {
        scrollToTop.style.display = "none";
      }
    }
  });

  // Smooth scrolling using Bootstrap's scroll behavior
  document.querySelectorAll('a.scroll-to-top').forEach(function(anchor) {
    anchor.addEventListener('click', function(e) {
      e.preventDefault();
      const targetId = this.getAttribute('href');
      const targetElement = document.querySelector(targetId);
      if (targetElement) {
        targetElement.scrollIntoView({ behavior: "smooth", block: "start" });
      }
    });
  });

})();
