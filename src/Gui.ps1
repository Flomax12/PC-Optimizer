# ============================================================================
#  Gui.ps1 - Interfaz WPF
# ============================================================================
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PC Optimizer - Windows 11" Height="800" Width="1120"
        MinHeight="620" MinWidth="900" WindowStartupLocation="CenterScreen"
        Background="#16161A" FontFamily="Segoe UI Variable Text, Segoe UI">

  <Window.Resources>
    <SolidColorBrush x:Key="Bg"     Color="#16161A"/>
    <SolidColorBrush x:Key="Card"   Color="#212127"/>
    <SolidColorBrush x:Key="Line"   Color="#33333C"/>
    <SolidColorBrush x:Key="Txt"    Color="#F2F2F5"/>
    <SolidColorBrush x:Key="Muted"  Color="#9A9AA5"/>
    <SolidColorBrush x:Key="Accent" Color="#4CC2FF"/>

    <Style TargetType="TextBlock">
      <Setter Property="Foreground" Value="{StaticResource Txt}"/>
      <Setter Property="TextWrapping" Value="Wrap"/>
    </Style>

    <Style x:Key="Boton" TargetType="Button">
      <Setter Property="Foreground" Value="#F2F2F5"/>
      <Setter Property="Background" Value="#2E2E36"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="BorderBrush" Value="#3D3D48"/>
      <Setter Property="Padding" Value="16,9"/>
      <Setter Property="Margin" Value="0,0,8,0"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" CornerRadius="6" Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"
                                Margin="{TemplateBinding Padding}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="b" Property="Background" Value="#3A3A45"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Opacity" Value="0.4"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="BotonPrimario" TargetType="Button" BasedOn="{StaticResource Boton}">
      <Setter Property="Background" Value="#4CC2FF"/>
      <Setter Property="Foreground" Value="#08202B"/>
      <Setter Property="BorderBrush" Value="#4CC2FF"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
    </Style>

    <Style TargetType="CheckBox">
      <Setter Property="Foreground" Value="{StaticResource Txt}"/>
      <Setter Property="VerticalAlignment" Value="Top"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Border Background="Transparent">
              <Grid>
                <Grid.ColumnDefinitions>
                  <ColumnDefinition Width="Auto"/>
                  <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Border x:Name="box" Width="19" Height="19" CornerRadius="4"
                        Background="#1A1A20" BorderBrush="#5A5A68" BorderThickness="1.4"
                        VerticalAlignment="Top">
                  <Path x:Name="tick" Data="M 3,8 L 7,12 L 15,3" Stroke="#08202B" StrokeThickness="2.2"
                        Visibility="Collapsed" StrokeEndLineCap="Round" StrokeStartLineCap="Round"/>
                </Border>
                <ContentPresenter Grid.Column="1" Margin="10,0,0,0" VerticalAlignment="Top"/>
              </Grid>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="box"  Property="Background"  Value="#4CC2FF"/>
                <Setter TargetName="box"  Property="BorderBrush" Value="#4CC2FF"/>
                <Setter TargetName="tick" Property="Visibility"  Value="Visible"/>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="box" Property="BorderBrush" Value="#4CC2FF"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Opacity" Value="0.45"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style TargetType="TabItem">
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="TabItem">
            <Border x:Name="b" CornerRadius="7" Margin="0,0,6,0" Padding="18,9" Background="Transparent">
              <ContentPresenter ContentSource="Header" HorizontalAlignment="Center"/>
              <Border.RenderTransform><TranslateTransform/></Border.RenderTransform>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsSelected" Value="True">
                <Setter TargetName="b" Property="Background" Value="#2E2E38"/>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="b" Property="Background" Value="#26262E"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- plantilla propia: la de serie pinta un panel blanco bajo las pestañas -->
    <Style TargetType="TabControl">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="TabControl">
            <Grid>
              <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
              </Grid.RowDefinitions>
              <TabPanel Grid.Row="0" IsItemsHost="True" Panel.ZIndex="1"
                        Background="Transparent" Margin="0,0,0,4"/>
              <Border Grid.Row="1" Background="Transparent">
                <ContentPresenter ContentSource="SelectedContent"/>
              </Border>
            </Grid>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Grid Margin="18">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <!-- ================= cabecera ================= -->
    <Border Grid.Row="0" Background="{StaticResource Card}" CornerRadius="10" Padding="18,14">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <StackPanel>
          <TextBlock Text="PC Optimizer" FontSize="21" FontWeight="SemiBold"/>
          <TextBlock x:Name="TxtSistema" Foreground="{StaticResource Muted}" FontSize="12" Margin="0,4,0,0"/>
          <TextBlock x:Name="TxtHardware" Foreground="{StaticResource Muted}" FontSize="12" Margin="0,2,0,0"/>
        </StackPanel>
        <Border Grid.Column="1" x:Name="BadgeAdmin" CornerRadius="6" Padding="12,6"
                VerticalAlignment="Top" Background="#1E3A24">
          <TextBlock x:Name="TxtAdmin" FontSize="12" FontWeight="SemiBold" Foreground="#7DDF8E"/>
        </Border>
      </Grid>
    </Border>

    <!-- ================= aviso ================= -->
    <Border Grid.Row="1" Background="#1B2A33" BorderBrush="#27506B" BorderThickness="1"
            CornerRadius="8" Padding="14,10" Margin="0,12,0,12">
      <TextBlock FontSize="12.5" Foreground="#BFE3F5" TextWrapping="Wrap">
        <Run FontWeight="SemiBold" Text="Tu Windows 11 sigue siendo bonito."/>
        <Run Text=" Esta app NUNCA toca animaciones, transparencias, Mica, esquinas redondeadas, Snap Layouts, efectos visuales, Windows Defender ni Windows Update. Todo cambio queda respaldado y se puede revertir desde la pestaña Revertir."/>
      </TextBlock>
    </Border>

    <!-- ================= pestañas ================= -->
    <TabControl Grid.Row="2" x:Name="Tabs">
      <TabItem>
        <TabItem.Header><TextBlock Text="Básico" FontSize="13.5" FontWeight="SemiBold"/></TabItem.Header>
        <Grid>
          <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
          <TextBlock Grid.Row="0" Margin="4,12,4,10" Foreground="{StaticResource Muted}" FontSize="12.5"
            Text="Limpieza y ajustes sin ningún riesgo. Recomendado para cualquier PC, incluso recién formateado. Nada de esto puede romper nada."/>
          <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Padding="0,0,10,0">
            <StackPanel x:Name="PanelBasico"/>
          </ScrollViewer>
        </Grid>
      </TabItem>

      <TabItem>
        <TabItem.Header><TextBlock Text="Medio" FontSize="13.5" FontWeight="SemiBold"/></TabItem.Header>
        <Grid>
          <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
          <TextBlock Grid.Row="0" Margin="4,12,4,10" Foreground="{StaticResource Muted}" FontSize="12.5"
            Text="Telemetría, procesos en segundo plano y bloatware. Ganancia real en RAM y uso de disco. Riesgo bajo y todo reversible."/>
          <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Padding="0,0,10,0">
            <StackPanel x:Name="PanelMedio"/>
          </ScrollViewer>
        </Grid>
      </TabItem>

      <TabItem>
        <TabItem.Header><TextBlock Text="Avanzado" FontSize="13.5" FontWeight="SemiBold"/></TabItem.Header>
        <Grid>
          <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
          <TextBlock Grid.Row="0" Margin="4,12,4,10" Foreground="#E8B84B" FontSize="12.5"
            Text="Ajustes de rendimiento profundo. Cada uno tiene un compromiso: léelo antes de marcarlo. Los que traen advertencia vienen desmarcados a propósito."/>
          <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Padding="0,0,10,0">
            <StackPanel x:Name="PanelAvanzado"/>
          </ScrollViewer>
        </Grid>
      </TabItem>

      <TabItem>
        <TabItem.Header><TextBlock Text="Fortnite" FontSize="13.5" FontWeight="SemiBold"/></TabItem.Header>
        <Grid>
          <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
          <TextBlock Grid.Row="0" Margin="4,12,4,10" Foreground="#9AE6A0" FontSize="12.5"
            Text="Latencia de entrada minima. Esta es solo la mitad de Windows: la otra mitad esta en el panel de NVIDIA, los ajustes del juego, la BIOS y el OSD del monitor. Abre GUIA-FORTNITE.md con el boton de abajo."/>
          <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Padding="0,0,10,0">
            <StackPanel x:Name="PanelFortnite"/>
          </ScrollViewer>
        </Grid>
      </TabItem>

      <TabItem>
        <TabItem.Header><TextBlock Text="Valorant" FontSize="13.5" FontWeight="SemiBold"/></TabItem.Header>
        <Grid>
          <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
          <TextBlock Grid.Row="0" Margin="4,12,4,10" Foreground="#FF9AA5" FontSize="12.5"
            Text="Incluye los ajustes de latencia comunes con Fortnite. Lo especifico de Riot va primero: si el juego no arranca o sale un error VAN, ejecuta antes de nada 'Comprobar requisitos de Vanguard'. Esta app NO toca ni elude el anticheat."/>
          <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Padding="0,0,10,0">
            <StackPanel x:Name="PanelValorant"/>
          </ScrollViewer>
        </Grid>
      </TabItem>

      <TabItem>
        <TabItem.Header><TextBlock Text="Revertir" FontSize="13.5" FontWeight="SemiBold"/></TabItem.Header>
        <Grid>
          <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
          <TextBlock Grid.Row="0" Margin="4,12,4,10" Foreground="{StaticResource Muted}" FontSize="12.5"
            Text="Cambios aplicados con esta app. Cada uno guarda el valor exacto que tenía antes y se restaura tal cual."/>
          <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Padding="0,0,10,0">
            <StackPanel x:Name="PanelRevertir"/>
          </ScrollViewer>
          <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="4,12,0,0">
            <Button x:Name="BtnRevertirTodo" Style="{StaticResource Boton}" Content="Revertir absolutamente todo"/>
            <Button x:Name="BtnRefrescar"    Style="{StaticResource Boton}" Content="Actualizar lista"/>
          </StackPanel>
        </Grid>
      </TabItem>

      <TabItem>
        <TabItem.Header><TextBlock Text="Registro" FontSize="13.5" FontWeight="SemiBold"/></TabItem.Header>
        <Grid Margin="0,12,0,0">
          <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
          <Border Grid.Row="0" Background="#0F0F13" CornerRadius="8" BorderBrush="{StaticResource Line}" BorderThickness="1">
            <TextBox x:Name="TxtLog" Background="Transparent" Foreground="#C8C8D2" BorderThickness="0"
                     FontFamily="Cascadia Mono, Consolas" FontSize="12" Padding="12"
                     IsReadOnly="True" VerticalScrollBarVisibility="Auto" TextWrapping="NoWrap"
                     HorizontalScrollBarVisibility="Auto"/>
          </Border>
          <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,10,0,0">
            <Button x:Name="BtnGuiaFn"      Style="{StaticResource Boton}" Content="Abrir GUIA-FORTNITE.md"/>
            <Button x:Name="BtnGuiaVal"     Style="{StaticResource Boton}" Content="Abrir GUIA-VALORANT.md"/>
            <Button x:Name="BtnAbrirLog"    Style="{StaticResource Boton}" Content="Abrir carpeta de registros"/>
            <Button x:Name="BtnAbrirBackup" Style="{StaticResource Boton}" Content="Ver respaldo (backup.json)"/>
          </StackPanel>
        </Grid>
      </TabItem>
    </TabControl>

    <!-- ================= barra inferior ================= -->
    <Border Grid.Row="3" Background="{StaticResource Card}" CornerRadius="10" Padding="16,12" Margin="0,14,0,0">
      <Grid>
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <Grid Grid.Row="0">
          <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <StackPanel Orientation="Horizontal">
            <Button x:Name="BtnPunto"    Style="{StaticResource Boton}"         Content="Crear punto de restauración"/>
            <Button x:Name="BtnMarcarRec" Style="{StaticResource Boton}"        Content="Marcar recomendados"/>
            <Button x:Name="BtnDesmarcar" Style="{StaticResource Boton}"        Content="Desmarcar todo"/>
            <Button x:Name="BtnAplicar"  Style="{StaticResource BotonPrimario}" Content="Aplicar seleccionados"/>
          </StackPanel>
          <TextBlock x:Name="TxtEstado" Grid.Column="1" VerticalAlignment="Center" Margin="16,0,0,0"
                     FontSize="12.5" Foreground="{StaticResource Muted}" TextTrimming="CharacterEllipsis"/>
        </Grid>
        <ProgressBar x:Name="Barra" Grid.Row="1" Height="4" Margin="0,12,0,0" Minimum="0" Maximum="100"
                     Background="#2A2A32" Foreground="#4CC2FF" BorderThickness="0"/>
      </Grid>
    </Border>
  </Grid>
</Window>
'@

function Show-OptimizerGui {
    # -SoloConstruir arma toda la ventana y sus tarjetas pero no la muestra.
    # Lo usa Probar.ps1 como prueba de humo.
    param([switch]$SoloConstruir)

    $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
    $win    = [Windows.Markup.XamlReader]::Load($reader)

    $ctl = @{}
    foreach ($n in @('TxtSistema','TxtHardware','TxtAdmin','BadgeAdmin','PanelBasico','PanelMedio',
                     'PanelAvanzado','PanelFortnite','PanelValorant','PanelRevertir','TxtLog','BtnAplicar','BtnPunto','BtnMarcarRec',
                     'BtnDesmarcar','BtnRevertirTodo','BtnRefrescar','BtnAbrirLog','BtnAbrirBackup','BtnGuiaFn','BtnGuiaVal',
                     'TxtEstado','Barra','Tabs')) {
        $ctl[$n] = $win.FindName($n)
    }

    # ---- utilidades de UI ---------------------------------------------------
    $refrescarUI = { $win.Dispatcher.Invoke([action]{}, [Windows.Threading.DispatcherPriority]::ContextIdle) }

    $script:LogSink = {
        param($msg, $nivel)
        $prefijo = switch ($nivel) { 'OK' {'  ok  '} 'ERROR' {' ERROR'} 'WARN' {' aviso'} 'PASO' {'  >>  '} default {'      '} }
        $ctl.TxtLog.AppendText(('[{0}]{1} {2}{3}' -f (Get-Date -Format 'HH:mm:ss'), $prefijo, $msg, [Environment]::NewLine))
        $ctl.TxtLog.ScrollToEnd()
        if ($nivel -in 'PASO','ERROR','OK') { $ctl.TxtEstado.Text = $msg }
        & $refrescarUI
    }

    # ---- cabecera -----------------------------------------------------------
    $info = Get-SystemSummary
    $ctl.TxtSistema.Text  = "$($info.SO)   -   encendido hace $($info.Uptime)   -   $($info.DiscoSO) en $env:SystemDrive"
    $ctl.TxtHardware.Text = "$($info.CPU)  -  $($info.Nucleos)  -  $($info.RAM) RAM  -  $($info.GPU)"

    if (Test-Admin) {
        $ctl.TxtAdmin.Text = "Administrador"
    } else {
        $ctl.TxtAdmin.Text = "SIN permisos de administrador"
        $ctl.TxtAdmin.Foreground   = '#FF9A9A'
        $ctl.BadgeAdmin.Background = '#3A1E1E'
        $ctl.BtnAplicar.IsEnabled = $false
        $ctl.BtnPunto.IsEnabled   = $false
    }

    # ---- construccion de tarjetas ------------------------------------------
    $script:Casillas = @{}
    $script:SincronizandoCasillas = $false

    $colorRiesgo = @{ 'Ninguno'='#3E8E4F'; 'Bajo'='#4E8B3E'; 'Medio'='#B8862B'; 'Alto'='#C0392B' }

    function New-TarjetaTweak {
        param($Tweak, $Aplicado)

        $borde = New-Object Windows.Controls.Border
        $borde.Background      = '#212127'
        $borde.BorderBrush     = if ($Aplicado) { '#3E8E4F' } else { '#2C2C35' }
        $borde.BorderThickness = 1
        $borde.CornerRadius    = 8
        $borde.Padding         = '14,12'
        $borde.Margin          = '2,0,2,9'

        $chk = New-Object Windows.Controls.CheckBox
        $chk.IsChecked = ($Tweak.PorDefecto -and -not $Aplicado)
        $chk.Tag       = $Tweak.Id

        $sp = New-Object Windows.Controls.StackPanel

        # titulo + etiquetas
        $fila = New-Object Windows.Controls.WrapPanel
        $t = New-Object Windows.Controls.TextBlock
        $t.Text = $Tweak.Nombre; $t.FontSize = 14; $t.FontWeight = 'SemiBold'
        $t.Foreground = '#F2F2F5'; $t.Margin = '0,0,10,0'
        [void]$fila.Children.Add($t)

        function New-Etiqueta { param($Texto, $Fondo, $Color)
            $b = New-Object Windows.Controls.Border
            $b.Background = $Fondo; $b.CornerRadius = 4; $b.Padding = '7,2'; $b.Margin = '0,1,6,0'
            $x = New-Object Windows.Controls.TextBlock
            $x.Text = $Texto; $x.FontSize = 10.5; $x.FontWeight = 'SemiBold'; $x.Foreground = $Color
            $b.Child = $x; $b
        }

        if ($Aplicado)          { [void]$fila.Children.Add((New-Etiqueta 'YA APLICADO' '#1E3A24' '#7DDF8E')) }
        if ($Tweak.Riesgo -ne 'Ninguno') {
            [void]$fila.Children.Add((New-Etiqueta "riesgo $($Tweak.Riesgo.ToLower())" '#26262F' $colorRiesgo[$Tweak.Riesgo]))
        }
        if ($Tweak.Reinicio)    { [void]$fila.Children.Add((New-Etiqueta 'requiere reinicio' '#26262F' '#9A9AA5')) }
        [void]$sp.Children.Add($fila)

        # descripcion
        $d = New-Object Windows.Controls.TextBlock
        $d.Text = $Tweak.Descripcion; $d.FontSize = 12.3; $d.Foreground = '#9A9AA5'; $d.Margin = '0,5,0,0'
        [void]$sp.Children.Add($d)

        # nota / advertencia
        if ($Tweak.Nota) {
            $n = New-Object Windows.Controls.TextBlock
            $n.Text = "! $($Tweak.Nota)"; $n.FontSize = 11.8; $n.Margin = '0,6,0,0'
            $n.Foreground = if ($Tweak.Riesgo -eq 'Alto') { '#FF8F8F' } else { '#E8B84B' }
            [void]$sp.Children.Add($n)
        }

        $chk.Content = $sp
        $borde.Child = $chk

        # un tweak puede aparecer en varias pestanas (Fortnite y Valorant comparten
        # los de latencia): guardamos TODAS sus casillas y las mantenemos en sincronia
        if (-not $script:Casillas.ContainsKey($Tweak.Id)) {
            $script:Casillas[$Tweak.Id] = New-Object System.Collections.ArrayList
        }
        [void]$script:Casillas[$Tweak.Id].Add($chk)

        $sincronizar = {
            if ($script:SincronizandoCasillas) { return }
            $script:SincronizandoCasillas = $true
            try {
                foreach ($otra in $script:Casillas[$this.Tag]) {
                    if (-not [object]::ReferenceEquals($otra, $this)) { $otra.IsChecked = $this.IsChecked }
                }
            } finally { $script:SincronizandoCasillas = $false }
        }
        $chk.Add_Checked($sincronizar)
        $chk.Add_Unchecked($sincronizar)

        $borde
    }

    function Build-Panel {
        param($Panel, $Nivel)
        $Panel.Children.Clear()
        $aplicados = Get-AppliedTweakIds
        $porCategoria = Get-Catalogo -Nivel $Nivel | Group-Object Categoria | Sort-Object Name
        foreach ($g in $porCategoria) {
            $h = New-Object Windows.Controls.TextBlock
            $h.Text = $g.Name.ToUpper(); $h.FontSize = 11; $h.FontWeight = 'Bold'
            $h.Foreground = '#6E6E7C'; $h.Margin = '4,10,0,8'
            [void]$Panel.Children.Add($h)
            foreach ($tw in $g.Group) {
                [void]$Panel.Children.Add((New-TarjetaTweak $tw ($aplicados -contains $tw.Id)))
            }
        }
    }

    function Build-Revertir {
        $ctl.PanelRevertir.Children.Clear()
        $aplicados = @(Get-AppliedTweakIds)
        if ($aplicados.Count -eq 0) {
            $t = New-Object Windows.Controls.TextBlock
            $t.Text = 'Todavía no has aplicado ningún cambio con esta app.'
            $t.Foreground = '#6E6E7C'; $t.Margin = '4,16,0,0'; $t.FontSize = 13
            [void]$ctl.PanelRevertir.Children.Add($t)
            return
        }
        foreach ($id in ($aplicados | Sort-Object)) {
            $tw = Get-TweakById $id
            $borde = New-Object Windows.Controls.Border
            $borde.Background = '#212127'; $borde.CornerRadius = 8
            $borde.Padding = '14,11'; $borde.Margin = '2,0,2,8'
            $g = New-Object Windows.Controls.Grid
            $c1 = New-Object Windows.Controls.ColumnDefinition; $c1.Width = '*'
            $c2 = New-Object Windows.Controls.ColumnDefinition; $c2.Width = 'Auto'
            [void]$g.ColumnDefinitions.Add($c1); [void]$g.ColumnDefinitions.Add($c2)

            $t = New-Object Windows.Controls.TextBlock
            $t.Text = if ($tw) { $tw.Nombre } else { $id }
            $t.FontSize = 13.5; $t.Foreground = '#F2F2F5'; $t.VerticalAlignment = 'Center'
            [void]$g.Children.Add($t)

            $b = New-Object Windows.Controls.Button
            $b.Content = 'Revertir'; $b.Style = $win.FindResource('Boton'); $b.Tag = $id
            $b.Margin = '10,0,0,0'
            [Windows.Controls.Grid]::SetColumn($b, 1)
            $b.Add_Click({
                $tid = $this.Tag
                Undo-Tweak $tid | Out-Null
                Build-Todo
            })
            [void]$g.Children.Add($b)
            $borde.Child = $g
            [void]$ctl.PanelRevertir.Children.Add($borde)
        }
    }

    function Build-Todo {
        $script:Casillas.Clear()
        Build-Panel $ctl.PanelBasico   'Basico'
        Build-Panel $ctl.PanelMedio    'Medio'
        Build-Panel $ctl.PanelAvanzado 'Avanzado'
        Build-Panel $ctl.PanelFortnite 'Fortnite'
        Build-Panel $ctl.PanelValorant 'Valorant'
        Build-Revertir
    }
    Build-Todo

    # ---- acciones -----------------------------------------------------------
    $ctl.BtnPunto.Add_Click({
        $ctl.Barra.IsIndeterminate = $true
        $ctl.TxtEstado.Text = 'Creando punto de restauración, esto tarda un poco...'
        & $refrescarUI
        $ok = New-OptRestorePoint
        $ctl.Barra.IsIndeterminate = $false
        [Windows.MessageBox]::Show(
            $(if ($ok) { 'Punto de restauración creado. Si algo sale mal podrás volver a este estado desde Configuración > Sistema > Recuperación.' }
              else     { 'No se pudo crear el punto de restauración. Activa "Protección del sistema" en la unidad C: y vuelve a intentarlo. Revisa la pestaña Registro para el detalle.' }),
            'Punto de restauración', 'OK',
            $(if ($ok) { 'Information' } else { 'Warning' })) | Out-Null
    })

    $ctl.BtnMarcarRec.Add_Click({
        $aplicados = Get-AppliedTweakIds
        foreach ($tw in (Get-Catalogo)) {
            if ($script:Casillas.ContainsKey($tw.Id)) {
                foreach ($c in $script:Casillas[$tw.Id]) {
                    $c.IsChecked = ($tw.PorDefecto -and ($aplicados -notcontains $tw.Id))
                }
            }
        }
        $ctl.TxtEstado.Text = 'Marcadas las opciones recomendadas de los tres niveles.'
    })

    $ctl.BtnDesmarcar.Add_Click({
        foreach ($lista in $script:Casillas.Values) { foreach ($c in $lista) { $c.IsChecked = $false } }
        $ctl.TxtEstado.Text = 'Nada seleccionado.'
    })

    $ctl.BtnAplicar.Add_Click({
        $ids = @($script:Casillas.GetEnumerator() |
                 Where-Object { @($_.Value | Where-Object IsChecked).Count -gt 0 } |
                 ForEach-Object { $_.Key })
        if ($ids.Count -eq 0) {
            [Windows.MessageBox]::Show('No has seleccionado ninguna optimización.', 'Nada que hacer', 'OK', 'Information') | Out-Null
            return
        }
        $seleccion = @($ids | ForEach-Object { Get-TweakById $_ })
        $altos     = @($seleccion | Where-Object Riesgo -eq 'Alto')
        $reinicio  = @($seleccion | Where-Object Reinicio)

        $msg = "Se van a aplicar $($ids.Count) optimizaciones.`n`n"
        if ($altos.Count)    { $msg += "ATENCIÓN, riesgo alto seleccionado:`n" + (($altos | ForEach-Object { "  - $($_.Nombre)" }) -join "`n") + "`n`n" }
        if ($reinicio.Count) { $msg += "$($reinicio.Count) requieren reiniciar para tener efecto.`n`n" }
        $msg += 'Todo queda respaldado y es reversible desde la pestaña Revertir (excepto la eliminación de apps preinstaladas).' + "`n`n" + '¿Continuar?'

        if ([Windows.MessageBox]::Show($msg, 'Confirmar', 'YesNo', 'Question') -ne 'Yes') { return }

        $ctl.BtnAplicar.IsEnabled = $false
        $ctl.Tabs.SelectedIndex   = 6      # pestaña Registro
        $ctl.Barra.Value = 0
        $i = 0; $ok = 0; $fail = 0
        Write-Opt "===== inicio: $($ids.Count) optimizaciones =====" 'PASO'

        foreach ($tw in $seleccion) {
            if (Invoke-Tweak $tw) { $ok++ } else { $fail++ }
            $i++
            $ctl.Barra.Value = ($i / $ids.Count) * 100
            & $refrescarUI
        }

        Write-Opt "===== fin: $ok correctas, $fail con error =====" 'PASO'
        $ctl.BtnAplicar.IsEnabled = $true

        Build-Todo

        $final = "Listo: $ok aplicadas" + $(if ($fail) { ", $fail con error (mira el Registro)" } else { '' }) + '.'
        if ($reinicio.Count) { $final += "`n`nReinicia el PC para que $($reinicio.Count) de ellas tengan efecto." }
        [Windows.MessageBox]::Show($final, 'Optimización terminada', 'OK', 'Information') | Out-Null
    })

    $ctl.BtnRevertirTodo.Add_Click({
        $aplicados = @(Get-AppliedTweakIds)
        if ($aplicados.Count -eq 0) { return }
        if ([Windows.MessageBox]::Show(
                "Se van a deshacer $($aplicados.Count) cambios y el sistema volverá a como estaba.`n`n¿Seguro?",
                'Revertir todo', 'YesNo', 'Warning') -ne 'Yes') { return }
        $ctl.Tabs.SelectedIndex = 6
        $i = 0
        foreach ($id in $aplicados) {
            Undo-Tweak $id | Out-Null
            $i++; $ctl.Barra.Value = ($i / $aplicados.Count) * 100; & $refrescarUI
        }
        Build-Todo
        [Windows.MessageBox]::Show('Todo revertido. Reinicia para que los cambios de kernel vuelvan a su estado original.',
            'Revertido', 'OK', 'Information') | Out-Null
    })

    $ctl.BtnRefrescar.Add_Click({ Build-Todo })
    $ctl.BtnGuiaVal.Add_Click({
        $g = Join-Path (Split-Path -Parent $PSScriptRoot) 'GUIA-VALORANT.md'
        if (Test-Path $g) { Start-Process notepad.exe $g }
        else { [Windows.MessageBox]::Show('No encuentro GUIA-VALORANT.md en la carpeta de la app.', 'Guia', 'OK', 'Warning') | Out-Null }
    })
    $ctl.BtnGuiaFn.Add_Click({
        $g = Join-Path (Split-Path -Parent $PSScriptRoot) 'GUIA-FORTNITE.md'
        if (Test-Path $g) { Start-Process notepad.exe $g }
        else { [Windows.MessageBox]::Show('No encuentro GUIA-FORTNITE.md en la carpeta de la app.', 'Guia', 'OK', 'Warning') | Out-Null }
    })
    $ctl.BtnAbrirLog.Add_Click({ Start-Process explorer.exe (Split-Path -Parent (Get-OptLogPath)) })
    $ctl.BtnAbrirBackup.Add_Click({
        $f = Join-Path (Split-Path -Parent $PSScriptRoot) 'data\backup.json'
        if (Test-Path $f) { Start-Process notepad.exe $f }
        else { [Windows.MessageBox]::Show('Todavía no hay respaldo: no has aplicado nada.', 'Respaldo', 'OK', 'Information') | Out-Null }
    })

    $tmp = Get-TempFootprintMB
    Write-Opt "PC Optimizer listo. Hay ~$tmp MB en archivos temporales y caches." 'INFO'
    if (-not (Test-Admin)) { Write-Opt 'Ejecutandose SIN permisos de administrador: cierra y usa Iniciar.bat' 'ERROR' }

    if ($SoloConstruir) {
        return [PSCustomObject]@{
            Ventana  = $win
            Tarjetas = $script:Casillas.Count
            Basico   = $ctl.PanelBasico.Children.Count
            Medio    = $ctl.PanelMedio.Children.Count
            Avanzado = $ctl.PanelAvanzado.Children.Count
            Fortnite = $ctl.PanelFortnite.Children.Count
            Valorant = $ctl.PanelValorant.Children.Count
        }
    }

    $win.ShowDialog() | Out-Null
}
