"""
Compute spectral geopotential `ϕ` from spectral temperature `Tabs`
and spectral topography `ϕ0`.
"""
function geopotential!( ϕ::Array{Complex{NF},3},      # geopotential
                        ϕ0::Array{Complex{NF},2},     # surface geopotential
                        Tabs::Array{Complex{NF},3},   # absolute Temperature
                        G::GeoSpectral{NF}) where {NF<:AbstractFloat}

    mx,nx,nlev = size(ϕ)

    @boundscheck size(ϕ) == size(Tabs) || throw(BoundsError())
    @boundscheck (mx,nx) == size(ϕ0)   || throw(BoundsError())

    @unpack xgeop1, xgeop2, lapserate_correction = G.geometry

    # BOTTOM LAYER
    # is last index k=end, integration over half a layer
    for j in 1:nx
        for i in 1:mx
            ϕ[i,j,end] = ϕ0[i,j] + xgeop1[end]*Tabs[i,j,end]
        end
    end

    # OTHER LAYERS
    # integrate two half-layers from bottom to top
    for k in nlev-1:-1:1
        for j in 1:nx
            for i in 1:mx
                ϕ[i,j,k] = ϕ[i,j,k+1] + xgeop2[k+1]*Tabs[i,j,k+1] + xgeop1[k]*Tabs[i,j,k]
            end
        end
    end

    # LAPSERATE CORRECTION IN THE FREE TROPOSPHERE (>nlev)
    # TODO only for spectral coefficients 1,: ?
    for k in 2:nlev-1
        for j in 1:nx
            ϕ[1,j,k] = ϕ[1,j,k] +
                    lapserate_correction[k-1]*(Tabs[1,j,k+1] - Tabs[1,j,k-1])
        end
    end
end