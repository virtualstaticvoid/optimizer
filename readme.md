## Optimizer
Performs minimization to solve for factor weights using multi-dimensional constrained optimization.

## Problem
The following formula shows the objective and constraints of the problem.

![Formula](https://github.com/virtualstaticvoid/optimizer/raw/master/doc/formula.png)

## Implementations

* Microsoft Excel - uses the `Solver` Add-In

* R implementations, using the following solvers from the [Rmetrics](https://r-forge.r-project.org/projects/rmetrics) project:
 * [Rdonlp2](https://r-forge.r-project.org/scm/viewvc.php/pkg/Rdonlp2/?root=rmetrics)
 * [Rnlminb2](https://r-forge.r-project.org/scm/viewvc.php/pkg/Rnlminb2/?root=rmetrics)
 * [Rsolnp2](https://r-forge.r-project.org/scm/viewvc.php/pkg/Rsolnp2/?root=rmetrics)

* Ruby - `GSL::MultiMin::FMinimizer` (currently without constraints )

